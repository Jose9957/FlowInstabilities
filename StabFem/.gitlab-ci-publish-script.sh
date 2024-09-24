#!/bin/bash

# =============================================================================
# This script provides a generic entrypoint to execute the StabFEM publish mode
#
# M. Pigou - IMFT
# =============================================================================

# ========================================================================
# Initialize options to defaults values
use_matlab="no"
help_asked="no"
skip_cached="no"
keep_neighbors_cache="yes"
regenerate_after_fail="no"
export SF_PUBLISH=1
# ========================================================================


# ========================================================================
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
#                      NOTHING TO MODIFY PAST HERE
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# ========================================================================

# COLORS
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BLACK='\033[0;30m'
PURPLE='\033[0;35m'
YELLOW='\033[0;33m'
NC='\033[0m'
make_bold="\033[1m"

okmark="\xE2\x9C\x94"
nokmark="\xE2\x9D\x8C"
arrowmark="\xE2\x86\x92"

print_limiter(){ echo -e "${BLACK} ============================================================ ${NC}" ; }
define_limiter(){
  len_msg="${#1}"
  len_limiter=$((len_msg+3))
  limiter=`eval printf '=%.0s' {1..$len_limiter}`
  echo $limiter
}
print_separator(){ echo -e "${BLACK} ---------------------------------------- ${NC}" ; }
print_msg(){ echo -e "${BLUE}$make_bold" " $1" "${NC}" ; }
print_success(){ echo -e "${GREEN}" "$okmark$make_bold$1" "${NC}" ; }
print_error(){ echo -e "${RED}" "$nokmark$make_bold$1" "${NC}" ; }
print_space(){ echo -e " " ; }
print_warning(){ echo -e "${PURPLE}$make_bold"  " $1" "${NC}" ; }

print_help(){
  print_limiter
  print_msg "Options of publish script:"
  print_limiter
  print_msg " -h|--help) Show this message "
  print_msg " --ignore-cache) Ignore the cache and run all publish scripts."
  print_msg " --invalidate-neighbors-cache) Disable the cache of all scripts from the same directory if any is invalid."
  print_msg " --regerenate-cache-if-fail) Regenerate previous cache if script execution failed."
  print_limiter
  print_space
}

print_options(){
  print_limiter
  print_msg "Selected options:"
  print_limiter
  print_msg " help_asked: $help_asked "
  print_msg " skip_cached: $skip_cached "
  print_msg " keep_neighbors_cache: $keep_neighbors_cache "
  print_msg " regenerate_after_fail: $regenerate_after_fail "
  print_limiter
  print_space
}

get_user_install_options(){
  POSITIONAL=()
  while [[ $# -gt 0 ]]
  do
    key="$1"
    case $key in
      -h|--help)
        help_asked="yes"
        shift
        ;;
      --ignore-cache)
        skip_cached="yes"
        shift
        ;;
      --invalidate-neighbors-cache)
        keep_neighbors_cache="no"
        shift
        ;;
      --regerenate-cache-if-fail)
        regenerate_after_fail="yes"
        shift
        ;;
      *)
        POSITIONAL+=("$1")
        print_error " Invalid option: $1"
        print_separator
        shift
        ;;
    esac
  done

  # --------------------------
  # help option:
  if [ "$help_asked" == "yes" ]; then
    print_help
    exit 0
  fi
}

print_script_status() {
  local -n scripts=$1
  local -n status=$2
  local i

  for i in "${!scripts[@]}"; do
    local script_fullpath="${scripts[$i]}"
    local script_status="${status[$i]}"
    local script_name=$(basename ${script_fullpath})
    local case_dir=$(dirname ${script_fullpath})
    local case_name=$(realpath --relative-to=${SFBASEDIR} ${case_dir})
    case_name="${case_name#*/}"

    case $script_status in
     1) # To execute (cache does not exist)
       echo -e "${GREEN}${makebold}$arrowmark [TO EXECUTE] ${BLUE}$case_name: $script_name (no cache existing)${NC}";;
     2) # To execute (cache exists but is ignored)
       echo -e "${GREEN}${makebold}$arrowmark [TO EXECUTE] ${BLUE}$case_name: $script_name (cache ignored)${NC}";;
     3) # To execute (cache exists but is outdated)
       echo -e "${GREEN}${makebold}$arrowmark [TO EXECUTE] ${BLUE}$case_name: $script_name (cache outdated)${NC}";;
     4) # Skipped (cache exists and is still valid)
       echo -e "${GREEN}${makebold}$okmark [SKIPPED]    $case_name: $script_name (cache still valid)${NC}";;
     5) # Executed (success)
       echo -e "${GREEN}${makebold}$okmark [SUCCESS]    $case_name: $script_name${NC}";;
     6) # Executed (failure but previous cache regenerated)
       echo -e "${YELLOW}${makebold}$nokmark[FAILED]    $case_name: $script_name (cache restored : $regenerate_after_fail )${NC}";;
     7) # Executed (failure and generating incomplete cache to publish)
       echo -e "${RED}${makebold}$nokmark[FAILED]     $case_name: $script_name (no cache to restore, incomplete cache kept)${NC}";;
    esac

  done

}

# ========================================================================
main(){
  # Get options
  get_user_install_options "$@"
  print_options

  # INTERNAL VARIABLES
  MATLAB_PATH=""
  FFBASEDIR=""
  SFBASEDIR="$(pwd)"
  [ -z $CI ] && IS_GITLABCI_ENV="no" || IS_GITLABCI_ENV="yes"

  # ---------------------------
  # - CHECKING ENVIRONMENT -
  # ---------------------------
  if [ $IS_GITLABCI_ENV == "yes" ]; then
    # > Failing if runner does not have the "prodcom" tag
    if [[  ! "$CI_RUNNER_TAGS" == *"prodcom"* ]]; then
      print_error "CI_RUNNER_TAGS must contain 'prodcom' tag."
      exit 1
    fi
    # Handling Ubuntu 16.04
    if [[ "$CI_RUNNER_TAGS" == *"u1604"* ]]; then
      # > Failing as FreeFem++ v4 is not supported on Ubuntu 16.04
      print_error "Publish script requires FreeFem++ v4, only handled on U18.04."
      exit 1
    elif [[ "$CI_RUNNER_TAGS" == *"u1804"* ]]; then
      source /PRODCOM/bin/config.sh
      module load Collection/.Singularity
      module load freefem++

      MATLAB_PATH="$(realpath /PRODCOM/bin/u18/matlab)"
    else
      print_error "CI_RUNNER_TAGS must contain u1804 tag."
    fi


  # -----------------------------
  # - Handling user environment -
  # -----------------------------
  else
    if [ -z $FFBASEDIR ]; then
      # Detecting FreeFem++ in PATH
      [ $(which FreeFem++) ] && FFBASEDIR=$(dirname $(dirname $(realpath $(which FreeFem++))))
    fi
    if [ -z $FFBASEDIR ]; then
      ## LIST OF HARD-CODED MATLAB PATH TO TEST (keep last match)
      shopt -s nullglob # DO NOT TOUCH THIS OPTION
      # David: you may add other paths in this list
      freefem_test_paths=("/usr" \
                        "/PRODCOM/Ubuntu18.04/Gcc-7.3.0-Mpich-3.2.1/freefem++/*" \ #IMFT default path
                        "/usr/local" \ #David mac
                        )
      shopt -u nullglob # DO NOT TOUCH THIS OPTION

      ## Searching for FreeFem++
      for freefem_test_path in ${freefem_test_paths[*]}; do
        [ -f $freefem_test_path/bin/FreeFem++ ] && FFBASEDIR=$freefem_test_path
      done
    fi
    if [ -z $MATLAB_PATH ]; then
      # Detecting Matlab in PATH
      [ $(which matlab) ] && MATLAB_PATH="$(realpath $(which matlab))"
    fi
    if [ -z $MATLAB_PATH ]; then
      ## LIST OF HARD-CODED MATLAB PATH TO TEST (keep last match)
      shopt -s nullglob # DO NOT TOUCH THIS OPTION
      # David: you may add other paths in this list
      matlab_test_paths=("/usr/bin/matlab" \
                        "/PRODCOM/MATLAB/matlabr201*/bin/matlab" \ #IMFT default path
                        "/usr/local/Matlab*/bin/matlab" \ #To be checked: default linux path?
                        "/Applications/MATLAB_R*.app/bin/matlab" \ #default MacOS path
                        )
      shopt -u nullglob # DO NOT TOUCH THIS OPTION

      ## Searching for MATLAB
      for matlab_test_path in ${matlab_test_paths[*]}; do
        [ -f $matlab_test_path ] && MATLAB_PATH=$matlab_test_path
      done
    fi
  fi

  if [ -z $FFBASEDIR ]; then
    print_error "Unable to locate FreeFem++."
    exit 1
  else
    print_success "FreeFem++ located in $FFBASEDIR."
  fi
  if [ -z $MATLAB_PATH ]; then
    print_error "Unable to locate MATLAB."
    exit 1
  else
    print_success "MATLAB located at $MATLAB_PATH"
  fi

  # =============================
  # == RUNNING PUBLISH SCRIPTS ==
  # =============================
  declare -a list_scripts=($(grep -rnw ./*_CASES/ --include \*.m -e '\[\[PUBLISH\]\]' -l))
  declare -a list_status=()

  #Detect whether each script needs to run
  # Possible status:
  # 1: To execute (cache does not exist)
  # 2: To execute (cache exists but is ignored)
  # 3: To execute (cache exists but is outdated)
  # 4: Skipped (cache exists and is still valid)
  # 5: Executed (success)
  # 6: Executed (failure but previous cache regenerated)
  # 7: Executed (failure but no previous cache to regenerate)
  for script_fullpath in "${list_scripts[@]}"; do
    script_name=$(basename ${script_fullpath})
    case_dir=$(dirname ${script_fullpath})

    cache_file=${case_dir}/.${script_name%.*}.cached_commit

    if [ ! -f ${cache_file} ]; then
      # There is no cache associated to this case
      list_status+=(1)
    elif [ $skip_cached == "yes" ]; then
      # Cache exists but is ignored
      list_status+=(2)
    else
      # Test whether cache is valid or outdated
      cur_commit="$(git rev-parse HEAD)"
      last_commit="$(cat ${cache_file})"
      list_checked_files=($script_fullpath \
                          $case_dir/SF_Custom.idp \
                          $case_dir/*.edp
                         )
      is_cache_valid="yes"
      for checked_file in $list_checked_files; do
        if [ -f $checked_file ]; then
          cached_time="$(git log -1 --format="%ad" --date=unix $last_commit -- $checked_file)"
          current_time="$(git log -1 --format="%ad" --date=unix $cur_commit -- $checked_file)"
          # if ${cached_time} empty, file did not exist when cache generated
          # if current_time>cached_time, file has been updated by a commit since cache generation
          if [ -z "${cached_time}" ] || [ "${current_time}" -gt "${cached_time}" ]; then
            is_cache_valid="no"
            break
          fi
        fi
      done
      # Set case status
      [ $is_cache_valid == "no" ] && list_status+=(3) || list_status+=(4)
    fi
  done

  #Invalidate cache of all scripts of a given folder if any script expired
  if [[ "$keep_neighbors_cache" == "no" ]]; then
    for i in "${!list_scripts[@]}"; do
      main_status="${list_status[$i]}"
      main_fullpath="${list_scripts[$i]}"
      main_dir=$(dirname ${main_fullpath})
      main_name=$(basename ${main_fullpath})

      # Skip if the cache is still valid
      if [[ "1 2 3" != *"${main_status}"* ]]; then continue; fi

      for j in "${!list_scripts[@]}"; do
        sub_status="${list_status[$j]}"
        sub_fullpath="${list_scripts[$j]}"
        sub_dir=$(dirname ${sub_fullpath})
        sub_name=$(basename ${sub_fullpath})

        if [[ "${sub_status}" == "4" ]]; then
          if [ "$main_dir" == "$sub_dir" ]; then
            print_msg "${sub_name} cache invalidated as ${main_name} cache is invalid."
            list_status[$j]=2
          fi
        fi
      done
    done
  fi


  #Run publish script
  autopublish="./autopublish.m"
  for i in "${!list_scripts[@]}"; do
    script_fullpath="${list_scripts[$i]}"
    script_name=$(basename ${script_fullpath})
    case_dir=$(dirname ${script_fullpath})

    case_name=$(realpath --relative-to=${SFBASEDIR} ${case_dir})
    case_name="${case_name#*/}"

    cache_file=${case_dir}/.${script_name%.*}.cached_commit
    timer_file=${case_dir}/.${script_name%.*}.cached_time

    script_status="${list_status[$i]}"

    # SKIPPING IF JOB DOES NOT NEED RUNNING
    if [[ "1 2 3" != *"${script_status}"* ]]; then
      print_msg "Skipping $case_name/${script_name}."
      continue
    fi

    # PRINTING CURRENT STACK OF CASES
    print_script_status list_scripts list_status

    # PREPARING JOB
    case_date=$(date)
    cat > $autopublish << EOL
% -- AUTOPUBLISH --"
addpath('./SOURCES_MATLAB')
SF_core_start
cd('${case_dir}')

fid = fopen('${script_name}','a');
fprintf(fid,"\n");
fprintf(fid,"%%\n");
fprintf(fid,"% This case was executed on StabFem server and published on website on ${case_date}");
fprintf(fid,"fclose(fopen('${script_name%.*}.success','w+')); % (line added automatically when publishing to detect success)");
fclose(fid);

publish('${script_name}','catchError', true);

if isfile('${script_name%.*}.success')
  exit(0);
else
  exit(1);
end
EOL
#"

    # SAVING CURRENT CACHE IF EXISTING
    if [[ "2 3" == *"${script_status}"* ]]; then
  	  shopt -s nullglob
  	  mkdir -p ${case_dir}/${script_name%.*}.oldcache/html
      for file in ${case_dir}/html/${script_name%.*}*; do
        mv $file ${case_dir}/${script_name%.*}.oldcache/html/$(basename $file)
      done
      for file in ${case_dir}/.${script_name%.*}.cached_*; do
        mv $file ${case_dir}/${script_name%.*}.oldcache/$(basename $file)
      done
  	  shopt -u nullglob
    else
    	# DELETING INCOMPLETE CACHE
  	  shopt -s nullglob
  	  for file in ${case_dir}/html/${script_name%.*}*; do
  	    rm -f $file
  	  done
      for file in ${case_dir}/.${script_name%.*}.cached_*; do
        rm -f $file
      done
	  fi

    # RUNNING SCRIPT
    cmd="${MATLAB_PATH} -nodesktop -nosplash -r autopublish"
    echo "Running cmd: '${cmd}' with ${autopublish}: "
    cat $autopublish
    /usr/bin/time -f %E -o $timer_file $cmd #NB : removed --quiet, to reintroduce
    exit_code=$?
    rm -f $autopublish

    # ANALYZING RESULT
    if [ $exit_code -eq 0 ]; then
	  # SCRIPT SUCCEEDED
      list_status[$i]=5
      echo "$(git rev-parse HEAD)" > ${cache_file}
      echo $CI_COMMIT_REF_NAME > ${case_dir}/.${script_name%.*}.cached_branch
      echo "Creating .cached_branch file :"
      cat ${case_dir}/.${script_name%.*}.cached_branch
    else
	  # SCRIPT FAILED
      if   [[ "2 3" == *"${script_status}"* ]];then
       if [[ "$regenerate_after_fail" == "yes" ]]; then
        # DELETE INCOMPLETE CACHE FROM FAILED EXECUTION
        for file in ${case_dir}/html/${script_name%.*}*; do
    	    rm -f $file
    	  done
        for file in ${case_dir}/.${script_name%.*}.cached_*; do
          rm -f $file
        done
	      # REGENERATING PREVIOUS CACHE
		    shopt -s nullglob
  		  for file in ${case_dir}/${script_name%.*}.oldcache/html/*; do
          mv $file ${case_dir}/html/;
        done
        for file in ${case_dir}/.${script_name%.*}.oldcache/.${script_name%.*}.cached_*; do
          mv $file ${case_dir}/$(basename $file)
        done
	      shopt -u nullglob
	   fi
        list_status[$i]=6
      else
	    # KEEP INCOMPLETE CACHE
        list_status[$i]=7
      fi
    fi

    # SAVING WORK IF [[WORK]] TAG IN EXECUTED SCRIPT
    grep -q '\[\[WORK\]\]' ${script_fullpath}
    if [ $? -eq 0 ] && [ ! -z ${SF_WORK} ]; then
      echo "Saving WORK tarball for the case ${case_name}."
      list_work_dirs=($(find ${case_dir} -type d -name 'WORK*' -exec basename {} \;))
      if [ ${#list_work_dirs[@]} -eq 0 ]; then
        echo "Couldn't find a directory starting by WORK in ${case_dir}."
      else
        work_save_dir="${SF_WORK}/${case_name}"
        work_tarball_path="${work_save_dir}/${CI_PIPELINE_ID}_$(date +%Y%m%d-%H%M)_${script_name%.*}_WORK.tar.gz"
        [ -d ${work_save_dir} ] || (mkdir -p ${work_save_dir} && chmod 775 ${work_save_dir})
        tar --atime-preserve -czf ${work_tarball_path} -C ${case_dir} ${list_work_dirs[@]}
        chmod 664 ${work_tarball_path}
        echo "Work tarball saved in ${work_tarball_path}."
      fi
    fi
  done


  print_script_status list_scripts list_status

}

# ==============================================================================
main "$@"
# ==============================================================================
