#!/bin/bash
#
# Author: jguymon@gmail.com
# Version: 0.0.1


# Set defaults
JSONFILE="./acme.json"
CERTRESOLVER="letsencrypt"
OUTPUTDIR="./certs"


function usage {
  sed 's;^  ;;' <<EOH
    PURPOSE:
      Used to export TLS certs from traefik acme.json file.

    USAGE:
      $(basename $0) (options) [DOMAIN, ...]
    
      If no DOMAIN is specified all domains will be exported.

    OPTIONS:
      -i JSONFILE
        json file to read from (default: "${JSONFILE}")
      -c CERTRESOLVER
        Name of the certificate resolver per traefik's configuration (default: "${CERTRESOLVER}")
      -o OUTPUTDIR
        directory to put cer and key files (default: "${OUTPUTDIR}")
      -l
        list available domains and then exit
      -v
        increase verbosity
      -h
        print this usage guide
EOH
}

function exportcert {
  local domain="${1:-domain.example.com}"
  local certtype="${2:-certificate}"
  local output="${OUTPUTDIR}/${domain}.${certtype:0:3}" 
  local filter="${FILTER}"' | select(.domain.main=="'"${domain}"'") | .'"${certtype}"

  # Export certificate or key to file
  jq -r "${filter}" "${JSONFILE}" \
  | base64 -d \
  | (umask 0177; cat > "${output}")

  # Record outputted files
  if [[ $? == 0 ]]; then
    EXPORTED+=("${output}")
  fi
}


# Process command line args
while getopts ":i:c:o:lvh" opt; do
  case $opt in
    i)
      JSONFILE="${OPTARG}"
      ;;
    c)
      CERTRESOLVER="${OPTARG}"
      ;;
    o)
      OUTPUTDIR="${OPTARG}"
      ;;
    v)
      VERBOSE=1
      ;;
    l)
      LISTDOMAINSONLY=1
      ;;
    h)
      usage
      exit
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    \:)
      echo "Option: -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Remove args from "$@"
shift $((OPTIND-1))


# Create base filter for jq
FILTER='."'"${CERTRESOLVER}"'".Certificates[]'


# Ensure input is readable
if ! [[ -r "${JSONFILE}" ]]; then
  printf 'Failed to read from "%s".\n' "${JSONFILE}"
  exit 1
fi


# Read json and ensure filter worked
json=$(jq -er "${FILTER}"'.domain.main' "${JSONFILE}")
if [[ ! $? == 0 ]]; then
  printf 'Failed to process json. You may need to correct the filter (-f).\n'
  exit 1
fi


# Fill domains array
declare -a domains
readarray -t domains < <(echo "${json}")


# Print and quit
if [[ ${LISTDOMAINSONLY} == 1 ]]; then
  printf '%s\n' "${domains[@]}"
  exit 0
fi


# Ensure at least one domain was found
if [[ ${#domains[@]} == 0 ]]; then
  printf 'Failed to find a domain. If this seems wrong check your filter (-f).\n'
  exit 1
fi


# Create OUTPUTDIR and ensure it is writable
mkdir -p "${OUTPUTDIR}" 
if ! [[ -w "${OUTPUTDIR}" ]]; then
  printf 'Failed to write to "%s".\n' "${OUTPUTDIR}"
  exit 1
fi


# Start extraction for each domain
for d in "${domains[@]}"; do

  # Skip this domain if it is not one of a specified list of domains
  if [[ $# -gt 0 ]]; then
    if [[ ! " ${@} " =~ " ${d} " ]]; then
      continue
    fi
  fi

  filterdomain="${FILTER}"' | select(.domain.main=="'"${d}"'")'

  # Export certificate and key
  exportcert "${d}" certificate
  exportcert "${d}" key

done


# Log discovery
if [[ ${VERBOSE} == 1 ]]; then
  printf 'Exported:\n'
  printf '  - %s\n' "${EXPORTED[@]}" 
fi
