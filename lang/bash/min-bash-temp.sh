#!/usr/bin/env bash
# min bash temp
# TODO script logic
function main() {
    msg "${GREEN}Hello World, param:$* ${NOFORMAT}"
}

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT
script_name="$(basename "${BASH_SOURCE[0]}")"
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# TODO shell usage
function usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]

Script description here.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-f, --flag      Some flag description
-p, --param     Some param description
EOF
  exit
}

# cleanup on exit
function cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # TODO script cleanup here
}
# print colorful message
function setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}
# print msg 
function msg() {
  echo >&2 -e "${1-}"
}
# exit shell with error
function die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}
# parse shell parameters
function parse_params() {
  # TODO default values of variables set from params
  flag=0
  param=''

  # when read has arguments option ++pos
  param_arg_pos=0
  while :; do
    param_arg_pos=$((param_arg_pos+1))
    case "${!param_arg_pos-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    -f | --flag)
      param_arg_pos=$((param_arg_pos+1))
      flag="${!param_arg_pos-}" ;; # example flag
    -p | --param) # example named parameter
      param_arg_pos=$((param_arg_pos+1))
      param="${!param_arg_pos-}"
      ;;
    -?*) die "Unknown option: ${!param_arg_pos}" ;;
    *) break ;;
    esac
  done

  args=("$@")

  # TODO check required params and arguments
  [[ "${param-}" -eq '' ]] && die "${RED}Missing required parameter: param. ${NOFORMAT}" # check arg param exists
  [[ ${#args[@]} -eq 0 ]] && die "${RED}Missing script arguments. ${NOFORMAT}" # check arg nums not 0

  return 0
}

parse_params "$@"
setup_colors

msg "${BLUE}script: ${YELLOW}${script_name} ${BLUE}location: ${YELLOW}${script_dir}${NOFORMAT}"
msg "${BLUE}Read parameters:${NOFORMAT}"
# TODO params
msg "- ${YELLOW}flag    \t:${NOFORMAT} ${flag}"
msg "- ${YELLOW}param   \t:${NOFORMAT} ${param}"
msg "- ${YELLOW}args    \t:${NOFORMAT} ${args[*]-}"
msg ""

# script logic start
main "$@"
msg "${BLUE}script ${YELLOW}${script_name} ${BLUE}exit.${NOFORMAT}"