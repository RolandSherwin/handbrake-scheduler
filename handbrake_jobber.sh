#!/bin/bash
while getopts i:o:m:l: option; do
  case $option in
    i) input_dir=$OPTARG;;
    o) output_dir=$OPTARG;;
    m) move_source_dir=$OPTARG;;
    l) log_dir=$OPTARG;;
  esac
done
# Set log_path to null if log_dir not provided, else have log file with current date
if [ -z "$log_dir" ];
  then
    log_path="/dev/null"
  else
    date=$(date +'%F-%R')
    log_path="$log_dir"/handbrake_jobber-"$date".log
fi
# If move_source_dir is not provided echo a warning message
if [ -z "$move_source_dir" ];
  then
    echo "handbrake_jobber WARNING: move_source_dir NOT set. Thus calling the script on the same folder, will re-encode the same files."
fi


process_wait(){
# If the any HandbrakeCLI instance is running, wait until it finishes.

  # Get PIDs of HandBrakeCLI processes
  eval processes=( $(ps aux | grep -i "HandBrakeCLI" | awk '{print $2}') )
  
  # If we get PID then wait till that process ends. If rpocess doesn't end it's in
  # loop forver. FIX LATER
  if [ ! -z "$processes" ];
    then	
      for i in $processes; do
        echo "handbrake_jobber INFO: HandbrakeCLI is already running.. waiting" 
        tail --pid=$i -f /dev/null
      done
      echo "handbrake_jobber INFO: Wait finished"
  fi  
}
create_directories() {
# Creates directory structure as needed for the passed file.
# ARG: FILE path. not directory

  parent_dir="$(dirname "$1")"
  # -p : no error if existing, make parent directories as needed
  mkdir -p "$parent_dir"
  
}

start_encode(){

  # to create dir structre, coz handbrake doesn't create on its own.
  create_directories "$output_file_path"
  # Echo nothing into handbrakeCLI to ensure its not using the same stdin as the script which. Before which handbrake stops after 1 file exectes.
  echo "" | HandBrakeCLI -i "$input_file_path" -o "$output_file_path" -e x265 -q 25 -r 60 -w 1920 -l 1080 --verbose=2 >> "$log_path" 2>&1
  HandBrakeCLI_exit_status=$?
  
}

move_original(){
# Only move the original file if HandBrakeCLI exited with exit status = 0. If -m not provided then dont move.  
 
  if [ "$HandBrakeCLI_exit_status" -ne 0 ];
    then
      echo "handbrake_jobber INFO: HandBrakeCLI had an error with file inputDir/${diff}. File will NOT be moved. The script will continue running.."
    else
      if [ -z "$move_source_dir" ];
        then
          echo "handbrake_jobber SUCCESS: Finished Encoding! Original file is NOT moved."
        else
          # Create the directory structre to preserve the original structure.
          create_directories "$move_file_path"
          move_file_dir="$(dirname "$move_file_path")"
          mv "$input_file_path" "$move_file_dir"
          echo "handbrake_jobber SUCCESS: Finished Encoding! Moved the file to new location!"
      fi
  fi
}

convert_each_file(){
  input_file_path=$1
  # To maintain the dir structure in the output location, get the difference between input_file_path and input_dir and 
  # create output_file_path by joining with the output_dir. 
  diff="${input_file_path#"$input_dir"}"
  # Doesnt matter if we have extra / in any of those variables. //dir///subdir////file is considered the same while executing as /dir/subdir/file 
  output_file_path="$output_dir/$diff"
  move_file_path="$move_source_dir/$diff"

  # Not required to call process_wait. Remove if you dont want to use it.
  echo "handbrake_jobber INFO: Encoding file: ${diff}"
  #process_wait
  start_encode
  move_original

}

main() {
# Find files in the given dir and executes a function on each of those files. The file path is 
# sent as arg to the function.
find "$input_dir" -type f -print0 | while IFS= read -r -d '' file; do convert_each_file "$file"; done
}

main
