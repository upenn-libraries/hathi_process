#!/bin/bash
set -e

# Set the CLI colors
blue='\033[0;34m'
nc='\033[0m'
red='\033[0;31m'

# Set additional_flags to an empty array and populate later
additional_flags=()

# Get CLI arguments
while getopts ":f:" opt; do
  case $opt in
  f) input_file=$OPTARG ;;
  *) additional_flags+="-$OPTARG" ;;
  esac
done

# Ensure the input file has been supplied
if [ -z "${input_file}" ]; then
  echo -e "${red}The file option (-f) is missing; please supply the location of the file to use.${nc}" >&2
  exit 1
fi

# Add any additional arguments to the additional_flags array
shift $(($OPTIND - 1))
additional_flags+="$@"

output_location=$(grep -r 'destination' ${input_file} | cut -d '|' -f2)
mounts=./.mounts

mkdir -p ${output_location}

# Build the image if it doesn't already exist
if [ -z $(docker images -q hathi_process) ]; then
  echo -e "${blue}Hathi Process image does not exist; building now.${nc}"
  docker build -t hathi_process .
fi

# Mount our file and output location in the container
docker_args=(
  "-v ${PWD}/${input_file}:/usr/src/app/${input_file}"
  "-v ${output_location}:${output_location}"
)

# If we have additional mounts then add them to our command
if [ -f "${mounts}" ]; then
  while IFS= read -r line; do
    docker_args+=("-v ${line}:${line}")
  done <"${mounts}"
fi

# Run the command within a container; cleaning up when finished
docker run -it --rm -e APP_UID=$(id -u) -e APP_GID=$(id -g) ${docker_args[@]} hathi_process ruby ruby/hathi_ocr.rb /usr/src/app/${input_file} ${additional_flags[@]}
