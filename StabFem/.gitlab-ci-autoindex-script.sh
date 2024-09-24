#!/bin/bash
echo "Generation of files AutomaticIndex.html"

base="./public"

declare -a CATEGORIES=('STABLE_CASES' 'TUTORIAL_CASES'
            'PUBLICATION_CASES' 'TEACHING_CASES' 'DEVELOPMENT_CASES'
            )

# List scripts and their properties
declare -a scripts_category=() # Category of the script, or "OTHER"
declare -a scripts_basename=() # Name of the matlab script file (without the .m extension)
declare -a scripts_dir=() # Directory of the matlab script file
declare -a scripts_name=() # Full name of the case (directory without its prefix)
declare -a scripts_date=() # Date of the script execution
declare -a scripts_status=() # Status of the script execution
declare -a scripts_runtime=() # Runtime of the script execution
declare -a scripts_branch=() # Branch in which the script was executed
declare -a scripts_enabled=() # Was the script execution enabled during last site generation?

today_date_raw=$(date "+%s")

for html_file in $(grep -rnw ./*_CASES --include \*.html -e '\[\[PUBLISH\]\]' -l|sort -t '/' -k 2 -k 3); do
  echo "html_file: ${html_file}"

  # Detect category
  script_category=$(echo ${html_file}|awk -F '/' '{print $2}')

  # Detect basename
  script_basename=$(basename ${html_file%.*})

  # Detect dir
  script_dir=$(dirname $(dirname ${html_file}))

  # Detect name
  script_name=$(realpath --relative-to=$(pwd)/${script_category} ${script_dir})

  # Detect date
  script_date=$(date -r ${html_file} "+%Y-%m-%d %H:%M:%S")
  script_date_raw=$(date -r ${html_file} "+%s")

  # Detect (and colorize) status
  [ -f ${script_dir}/.${script_basename}.cached_commit ] && \
    script_status="<span style=\"color:green\"> Success </span>" || script_status="<span style=\"color:red\"> Incomplete </span>"

  # Detect runtime
  if  [ -f ${script_dir}/.${script_basename}.cached_time ]; then
    script_runtime=$(cat ${script_dir}/.${script_basename}.cached_time)
  else
    script_runtime='???'
  fi

  # Detect branch
  if [ -f ${script_dir}/.${script_basename}.cached_branch ]; then
    script_branch=$(cat ${script_dir}/.${script_basename}.cached_branch)
  else
    script_branch='???'
  fi

  # Detect "followed" (and colorize)
  if [ -f ${script_dir}/${script_basename}.m ]; then
    grep '\[\[PUBLISH\]\]' ${script_dir}/${script_basename}.m -q
    [ $? -eq 0 ] && script_enabled="<span style=\"color:green\"> yes </span>" || script_enabled="<span style=\"color:red\"> no </span>"
  else
    script_enabled="<span style=\"color:red\"> no </span>"
  fi




  # Store script data
  set -f
  scripts_category+=("$script_category")
  scripts_basename+=("$script_basename")
  scripts_dir+=("$script_dir")
  scripts_name+=("$script_name")
  scripts_date+=("$script_date")
  scripts_date_raw+=("$script_date_raw")
  scripts_status+=("$script_status")
  scripts_runtime+=("$script_runtime")
  scripts_branch+=("$script_branch")
  scripts_enabled+=("$script_enabled")
  set +f
done

# prologue from template file
mkdir -p ${base}
cat .AutomaticIndex_Beginning.html > ${base}/AutomaticIndex.html
index_date=$(date)
echo "<h3> (Automatically generated on $index_date </h3> " >> ${base}/AutomaticIndex.html

#
# New part : "Latest codes"
#

  # Creating category section
  echo "### Category : Latest publication"
  echo "<br>" >> ${base}/AutomaticIndex.html
  echo "<h2> Latest publications : </h2>" >> ${base}/AutomaticIndex.html
  echo "<table style="width:100%">" >> ${base}/AutomaticIndex.html
  echo "  <tr> " >> ${base}/AutomaticIndex.html
  echo "   <th>Case</th> " >> ${base}/AutomaticIndex.html
  echo "   <th>Date</th> " >> ${base}/AutomaticIndex.html
  echo "   <th>Status / Followed </th> " >> ${base}/AutomaticIndex.html
  echo "   <th>Run time</th> " >> ${base}/AutomaticIndex.html
  echo "   <th> Branch </th> " >> ${base}/AutomaticIndex.html
  echo "  </tr> " >> ${base}/AutomaticIndex.html

  # Adding each script of the current category
  for i in "${!scripts_category[@]}"; do


    # Retrieving script information
    script_basename="${scripts_basename[$i]}"
    script_dir="${scripts_dir[$i]}"
    script_name="${scripts_name[$i]}"
    script_date="${scripts_date[$i]}"
    script_status="${scripts_status[$i]}"
    script_runtime="${scripts_runtime[$i]}"
    script_branch="${scripts_branch[$i]}"
    script_enabled="${scripts_enabled[$i]}"
    script_date_raw="${scripts_date_raw[$i]}"

  # Skipping current script if too old (NB 1296000 seconds is 15 days)
    if [ ${script_date_raw} -lt $((${today_date_raw}-1296000)) ];then
       continue
    fi
 # skipping if failed
    if
    [[ "${script_status}" == *"Incomplete"*   ]]; then
     continue
    fi
# Skipping current script if contains ".oldcache"
    if [[  "${script_dir}" = *"oldcache"* ]]; then
     continue
    fi

    # Copying html and figure files
    [ -d "${base}/${category}/${script_name}" ] || mkdir -p "${base}/${category}/${script_name}"
    shopt -s nullglob
    for file in $script_dir/html/${script_basename}*; do
      #echo "copying $file in newwebsite/${category}/${script_name}/"
      cp $file ${base}/${category}/${script_name}/$(basename $file)
    done
    shopt -u nullglob

    # Adding entry to scripts table
    echo "Adding ${script_name}/${script_basename}."
    echo "<tr>" >> ${base}/AutomaticIndex.html
    echo "<td><a href=\"./${category}/${script_name}/${script_basename}.html\"> ${script_name}/${script_basename}.m </a></td>" >> ${base}/AutomaticIndex.html
    echo "<td>$script_date</td>" >> ${base}/AutomaticIndex.html
    echo "<td>$script_status / $script_enabled</td>" >> ${base}/AutomaticIndex.html
    echo "<td>$script_runtime</td>" >> ${base}/AutomaticIndex.html
    echo "<td>$script_branch</td>" >> ${base}/AutomaticIndex.html
    echo "</tr>" >> ${base}/AutomaticIndex.html
  done

  # Section finalisation
  echo "</table>" >> ${base}/AutomaticIndex.html
  echo "<br>" >> ${base}/AutomaticIndex.html


#
# Main part of the script : loop over categories
#

CATEGORIES+=('OTHER')
for category in "${CATEGORIES[@]}"; do
  # Skipping CATEGORY if no script associated
  [[ ! " ${scripts_category[@]} " =~ " ${category} " ]] && continue

  # Creating category section
  echo "### Category : ${category}"
  echo "<br>" >> ${base}/AutomaticIndex.html
  echo "<h2> Content in ${category} : </h2>" >> ${base}/AutomaticIndex.html
  echo "<table style="width:100%">" >> ${base}/AutomaticIndex.html
  echo "  <tr> " >> ${base}/AutomaticIndex.html
  echo "   <th>Case</th> " >> ${base}/AutomaticIndex.html
  echo "   <th>Date</th> " >> ${base}/AutomaticIndex.html
  echo "   <th>Status / Followed </th> " >> ${base}/AutomaticIndex.html
  echo "   <th>Run time</th> " >> ${base}/AutomaticIndex.html
  echo "   <th> Branch </th> " >> ${base}/AutomaticIndex.html
  echo "  </tr> " >> ${base}/AutomaticIndex.html

  # Adding each script of the current category
  for i in "${!scripts_category[@]}"; do

    # Skipping current script if incorrect category
    [[ "${scripts_category[$i]}" == "${category}" ]] || continue

    # Skipping current script if contains ".oldcache" or is failed/disabled
#    [[ ! "${scripts_name[$i]}" = *"oldcache"* ]] || continue

    # Retrieving script information
    script_basename="${scripts_basename[$i]}"
    script_dir="${scripts_dir[$i]}"
    script_name="${scripts_name[$i]}"
    script_date="${scripts_date[$i]}"
    script_status="${scripts_status[$i]}"
    script_runtime="${scripts_runtime[$i]}"
    script_branch="${scripts_branch[$i]}"
    script_enabled="${scripts_enabled[$i]}"

      # Skipping current script if contains ".oldcache" or is failed/disabled
    if [[  "${script_dir}" = *"oldcache"* ]]; then
     echo " skipped oldcache"
     continue
    fi
    if
    [[ ("${script_status}" == *"Incomplete"*  && "${script_enabled}" == *"no"* ) ]]; then
     echo "skipped failed case"
     continue
    fi

    # Copying html and figure files
    [ -d "${base}/${category}/${script_name}" ] || mkdir -p "${base}/${category}/${script_name}"
    shopt -s nullglob
    for file in $script_dir/html/${script_basename}*; do
      #echo "copying $file in newwebsite/${category}/${script_name}/"
      cp $file ${base}/${category}/${script_name}/$(basename $file)
    done
    shopt -u nullglob

    # Adding entry to scripts table
    echo "Adding ${script_name}/${script_basename}."
    echo "<tr>" >> ${base}/AutomaticIndex.html
    echo "<td><a href=\"./${category}/${script_name}/${script_basename}.html\"> ${script_name}/${script_basename}.m </a></td>" >> ${base}/AutomaticIndex.html
    echo "<td>$script_date</td>" >> ${base}/AutomaticIndex.html
    echo "<td>$script_status / $script_enabled</td>" >> ${base}/AutomaticIndex.html
    echo "<td>$script_runtime</td>" >> ${base}/AutomaticIndex.html
    echo "<td>$script_branch</td>" >> ${base}/AutomaticIndex.html
    echo "</tr>" >> ${base}/AutomaticIndex.html
  done

  # Section finalisation
  echo "</table>" >> ${base}/AutomaticIndex.html
  echo "<br>" >> ${base}/AutomaticIndex.html
done



# File finalisation

cat .AutomaticIndex_Ending.html >> ${base}/AutomaticIndex.html
#cp ${base}/AutomaticIndex.html ${base}/index.html ! NO !
