#!/bin/bash

# ========================================================================
# This script provides a generic entrypoint to execute the StabFEM autorun
#
# M. Pigou - IMFT
# ========================================================================

# ========================================================================
# Initialize options to defaults values
interactive="no"
use_matlab="no"
freefem_version="4"
run_list="short"
omp_threads="1"
help_asked="no"
verbosity="0"
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
NC='\033[0m'
make_bold="\033[1m"

okmark="\xE2\x9C\x94"
nokmark="\xE2\x9D\x8C"

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
  print_msg "Options of autorun script:"
  print_limiter
  print_msg " -h|--help) Show this message "
  print_msg " -i|--interactive) Run the autorun in interactive mode"
  print_msg " -m|--matlab) Use matlab to execute StabFem (octave by default)"
  print_msg " --ffver [3|4]) Selects whether to use FreeFem++ version 3.X or 4.X (default)"
  print_msg " --list|--run [short|long|case_name]) Selects the list of autorun to execute"
  print_msg " --thread 1) Set the number of OpenMP threads to use."
  print_msg " -v|--verbose) Make autorun verbose (level 4)"
  print_msg " -d|--debug) Use debug level verbosity (level 8)"
  print_limiter
  print_space

  exit 0
}

print_options(){
  print_limiter
  print_msg "Selected options:"
  print_limiter
  print_msg " interactive: $interactive "
  print_msg " use_matlab: $use_matlab "
  print_msg " freefem_version: $freefem_version "
  print_msg " run_list: $run_list "
  print_msg " omp_threads: $omp_threads "
  print_msg " help_asked: $help_asked "
  print_msg " verbosity: $verbosity "
  print_limiter
  print_space
}

get_user_install_options(){
  POSITIONAL=()
  while [[ $# -gt 0 ]]
  do
    key="$1"
    case $key in
      -i|--interactive)
        interactive="yes"
        shift
        ;;
      -m|--matlab)
        use_matlab="yes"
        shift
        ;;
      --ffver)
        freefem_version="$2"
        shift
        shift
        ;;
      --list|--run)
        run_list="$2"
        shift
        shift
        ;;
      -v|--verbosity)
        verbosity="4"
        shift
        shift
        ;;
      -d|--debug)
        verbosity="8"
        shift
        shift
        ;;
      -t|--thread)
        omp_threads="$2"
        shift
        shift
        ;;
      -h|--help)
        help_asked="yes"
        shift
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
  fi

  # --------------------------
  # check ffver
  if [ ! "$freefem_version" == "3" ] && [ ! "$freefem_version" == "4" ]; then
    print_error "Invalid FreeFem++ version '${freefem_version}'."
    exit 1
  fi
}

# ========================================================================
main(){
  # Read env. var. options
  [ ! -z $SFARVER ] && run_list=$SFARVER
  [ ! -z $SF_AR_SFARVER ] && run_list=$SF_AR_SFARVER

  # Get options
  get_user_install_options "$@"
  print_options

  # INTERNAL VARIABLES
  MATLAB_PATH=""
  OCTAVE_PATH=""
  FFBASEDIR=""
  [ -z $CI ] && IS_GITLABCI_ENV="no" || IS_GITLABCI_ENV="yes"

  # ====================
  # == Locate FreeFem ==
  # ====================
  # ----------------------------------
  # - Handling Gitlab-CI environment -
  # ----------------------------------
  if [ "$IS_GITLABCI_ENV" == "yes" ]; then
    # > Failing if runner does not have the "prodcom" tag
    if [[  ! "$CI_RUNNER_TAGS" == *"prodcom"* ]]; then
      print_error "CI_RUNNER_TAGS must contain 'prodcom' tag."
      exit 1
    fi

    # Handling Ubuntu 16.04
    if [[ "$CI_RUNNER_TAGS" == *"u1604"* ]]; then
      # > Failing if FreeFem++ v4 asked, as not supported on Ubuntu 16.04
      if [ "$freefem_version" == "4" ]; then
        print_error "Only FreeFem++ 3.X is supported under Ubuntu 16.04."
        exit 1
      fi
      #> Loading freefem++ module
      source /PRODCOM/bin/config.sh
      module load mpich/3.2.0/gcc-5.4
      module load freefem/3.61-1/gcc-5.4_mpich-3.2
      export FFBASEDIR="/PRODCOM/Ubuntu16.04/freefem/3.61-1/gcc-5.4-mpich-3.2"

    # Handling Ubuntu 18.04
    elif [[ "$CI_RUNNER_TAGS" == *"u1804"* ]]; then
      #> loading freefem++ module
      source /PRODCOM/bin/config.sh
      module load Collection/All
      module load freefem++

    # Failing if other distribution
    else
      print_error "CI_RUNNER_TAGS must contain u1604 or u1804 tag."
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
      ## LIST OF HARD-CODED MATLAB PATH TO TEST (stop at first match)
      shopt -s nullglob # DO NOT TOUCH THIS OPTION
      # David: you may add other paths in this list
      freefem_test_paths=("/usr" \
                        "/PRODCOM/Ubuntu18.04/Gcc-7.3.0-Mpich-3.2.1/freefem++/*" \ #IMFT default path
                        )
      shopt -u nullglob # DO NOT TOUCH THIS OPTION

      ## Searching for FreeFem++
      for freefem_test_path in ${freefem_test_paths[*]}; do
        [ -f $freefem_test_path/bin/FreeFem++ ] && FFBASEDIR=$freefem_test_path
      done
    fi
  fi

  if [ -z $FFBASEDIR ]; then
    print_error "Unable to locate FreeFem++."
    exit 1
  else
    print_success "FreeFem++ located in $FFBASEDIR."
  fi

  # ==========================
  # == Locate Octave/Matlab ==
  # ==========================
  # ----------------------------------
  # - Handling Gitlab-CI environment -
  # ----------------------------------
  if [ "$IS_GITLABCI_ENV" == "yes" ]; then
    if [[ "$CI_RUNNER_TAGS" == *"u1604"* ]] && [[ "$use_matlab" == "no" ]]; then
      print_warning "Octave is unavailable under Ubuntu 16.04. Using matlab instead."
      use_matlab="yes"
    fi

    if [[ "$CI_RUNNER_TAGS" == *"u1604"* ]] && [[ "$use_matlab" == "yes" ]]; then
      MATLAB_PATH="$(realpath /PRODCOM/bin/u16/matlab)"
    elif [[ "$CI_RUNNER_TAGS" == *"u1804"* ]] && [[ "$use_matlab" == "yes" ]]; then
      MATLAB_PATH="$(realpath /PRODCOM/bin/u18/matlab)"
    elif [[ "$CI_RUNNER_TAGS" == *"u1804"* ]] && [[ "$use_matlab" == "no" ]]; then
    #  module load Octave/4.4.1-gcc-7.3.0-mpich-3.2.1
    # Maxime : use latest by default ?
      module load Octave
      OCTAVE_PATH="$(which octave)"
    fi

  # -----------------------------
  # - Handling user environment -
  # -----------------------------
  else
    if [ -z $MATLAB_PATH ]; then
      # Detecting Matlab in PATH
      [ $(which matlab) ] && MATLAB_PATH="$(realpath $(which matlab))"
    fi
    if [ -z $MATLAB_PATH ]; then
      ## LIST OF HARD-CODED MATLAB PATH TO TEST (stop at first match)
      shopt -s nullglob # DO NOT TOUCH THIS OPTION
      # David: you may add other paths in this list
      matlab_test_paths=("/usr/bin/matlab" \
                         "/PRODCOM/MATLAB/matlabr201*/bin/matlab" \ #IMFT default path
                         "/usr/local/Matlab*/bin/matlab" \ #To be checked: default linux path?
                         "/Applications/MATLAB_R*.app/bin/matlab" \ #default MacOS path?
                        )
      shopt -u nullglob # DO NOT TOUCH THIS OPTION

      ## Searching for MATLAB
      for matlab_test_path in ${matlab_test_paths[*]}; do
        [ -f $matlab_test_path ] && MATLAB_PATH=$matlab_test_path
      done
    fi

    if [ -z $OCTAVE_PATH ]; then
      # Detecting Octave in PATH
      [ $(which octave) ] && OCTAVE_PATH="$(realpath $(which octave))"
    fi
    if [ -z $OCTAVE_PATH ]; then
      ## LIST OF HARD-CODED OCTAVE PATH TO TEST (stop at first match)
      shopt -s nullglob # DO NOT TOUCH THIS OPTION
      octave_test_paths=("/usr/bin/octave" \
                        )
      shopt -u nullglob # DO NOT TOUCH THIS OPTION

      ## Searching for OCTAVE
      for octave_test_path in ${octave_test_paths[*]}; do
        if [ -f $octave_test_path ]; then
          OCTAVE_PATH=$octave_test_path
        fi
      done
    fi
  fi

  if [ "$use_matlab" == "yes" ]; then
    if [ -z $MATLAB_PATH ]; then
      print_error "Unable to locate MATLAB."
      exit 1
    else
      print_success "MATLAB located at $MATLAB_PATH"
    fi
  else
    if [ -z $OCTAVE_PATH ]; then
      print_error "Unable to locate Octave."
      exit 1
    else
      print_success "Octave located at $OCTAVE_PATH"
    fi
  fi

  # ==============================
  # == Defining autorun command ==
  # ==============================
  if [ "$interactive" == "no" ]; then
    if [ "$use_matlab" == "yes" ]; then
      cmd="${MATLAB_PATH} -nodesktop -nosplash -r autorun_core -logfile ../autorun.log"
    else
      cmd="${OCTAVE_PATH} --no-gui autorun_core.m | tee ../autorun.log"
    fi
  else
    export SFARKEEP=1
    if [ "$use_matlab" == "yes" ]; then
      cmd="${MATLAB_PATH} -r autorun_core"
    else
      cmd="${OCTAVE_PATH} autorun_core.m"
    fi
  fi

  # ====================================
  # == Defining tunning env variables ==
  # ====================================
  export SFBASEDIR="$(dirname $(realpath $0))"
  export SFARVER=${run_list}
  export SFARVERBOSITY=${verbosity}
  export FFBASEDIR=$FFBASEDIR
  export OMP_NUM_THREADS=${omp_threads}

  # =======================
  # == Executing autorun ==
  # =======================
  print_msg "Running an autorun with list tagued [$SFARVER]"
  print_msg "Running cmd: ${cmd}"

  cd AUTORUN
  $cmd
  exit $?
}

# ==============================================================================
main "$@"
# ==============================================================================
