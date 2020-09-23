#!/bin/bash
set -euxo pipefail

# Create /root/.edgerc file from env variable
echo -e "${EDGERC}" > ~/.edgerc

#  Set Variables
edgeworkersName=$1
network=$2
groupid=$3

akamai edgeworkers list-ids --json edgeworkers.json --section edgeworkers --edgerc ~/.edgerc
edgeworkersID=$(cat edgeworkers.json | jq --arg edgeworkersName "${edgeworkersName}" '.data[] | select(.name == $edgeworkersName) | .edgeWorkerId')

if [ -n "${WORKER_DIR}" ]; then
  GITHUB_WORKSPACE="${GITHUB_WORKSPACE}/${WORKER_DIR}"
fi

cd "${GITHUB_WORKSPACE}"

tarCommand='tar -czvf ~/deploy.tar.gz'
# check if needed files exist
mainJSFile='main.js'
bundleFile='bundle.json'
utilitiesDir='utils'
if [ -f $mainJSFile ] ; then 
  tarCommand=${tarCommand}" $mainJSFile"
else
  echo "Error: $mainJSFile is missing" && exit 123
fi 
if [ -f $bundleFile ] ; then 
  tarCommand=${tarCommand}" $bundleFile"
else
  echo "Error: $bundleFile is missing" && exit 123
fi 
# pack optional JS libraries if existing
if [ -d $utilitiesDir ] ; then 
  tarCommand=${tarCommand}" $utilitiesDir"
fi
# execute tar command
eval "$tarCommand";

if [ -n "$edgeworkersID" ]; then

   # UPLOAD edgeWorker
   echo "Uploading Edgeworker"
   akamai edgeworkers upload \
     --edgerc ~/.edgerc \
     --section edgeworkers \
     --bundle ~/deploy.tar.gz \
     "${edgeworkersID}"
   edgeworkersVersion=$(echo "$(<"${GITHUB_WORKSPACE}"/bundle.json)" | jq '.["edgeworker-version"]' | tr -d '"')
   echo "Activating Edgeworker Version: ${edgeworkersVersion}"

   # ACTIVATE edgeworker
   echo "Activating Edgeworker"
   akamai edgeworkers activate \
         --edgerc ~/.edgerc \
         --section edgeworkers \
         "${edgeworkersID}" \
         "${network}" \
         "${edgeworkersVersion}" |
           while read -r line; do
             if [[ $line =~ status ]] ; then
                status=$(echo "${line}" | tr -d -c 0-9)
                case $status in
                   200) echo "Activation Successful" ;;
                   201) echo "Activation Successful" ;;
                   400) echo "Previous activation still pending ... aborting" && exit 100 ;;
                   401) echo "Invalid authorization credentials ... aborting" && exit 101 ;;
                   403) echo "The client is not authorized to invoke the service ... aborting" && exit 102 ;;
                   422) echo "System limit reached ... aborting" && exit 103 ;;
                   502) echo "Gateway unavailable to process request ... aborting" && exit 104 ;;
                   503) echo "Service is temporarily unavailable ... aborting" && exit 105 ;;
                   *)   echo "$status!!  Activation: status not defined, confirm if activation was successful in control centre ... aborting" && exit 106 ;;
                esac
             fi
             if [[ $line =~ "error code" ]] ; then
               echo "${line}" && exit 123
             fi
           done
fi
if [ -z "$edgeworkersID" ]; then
    edgeworkersgroupID=${groupid}

    # Register ID
    echo "Registering Edgeworker Group Version: ${edgeworkersgroupID}"
    edgeworkerList=$(cat "$(akamai edgeworkers register \
                      --json --section edgeworkers \
                      --edgerc ~/.edgerc  \
                      "${edgeworkersgroupID}" \
                      "${edgeworkersName}")")
    echo "${edgeworkerList}"
    echo "edgeworker registered"
    edgeworkersID=$(echo "${edgeworkerList}" | jq '.data[] | .edgeWorkerId')
    edgeworkersgroupID=$(echo "${edgeworkerList}" | jq '.data[] | .groupId')
    echo "Uploading Edgeworker Version"

    # UPLOAD edgeWorker
    akamai edgeworkers upload \
      --edgerc ~/.edgerc \
      --section edgeworkers \
      --bundle ~/deploy.tar.gz \
      "${edgeworkersID}"
    edgeworkersVersion=$(echo "$(<"${GITHUB_WORKSPACE}"/bundle.json)" | jq '.["edgeworker-version"]' | tr -d '"')
    echo "Activating Edgeworker Version: ${edgeworkersVersion}"

    # ACTIVATE edgeworker
    echo "activating"
    akamai edgeworkers activate \
         --edgerc ~/.edgerc \
         --section edgeworkers \
         "${edgeworkersID}" \
         "${network}" \
         "${edgeworkersVersion}" |
           while read -r line; do
             if [[ $line =~ status ]] ; then
                status=$(echo "${line}" | tr -d -c 0-9)
                case $status in
                   200) echo "Activation Successful" ;;
                   201) echo "Activation Successful" ;;
                   400) echo "Previous activation still pending ... aborting" && exit 123 ;;
                   401) echo "Invalid authorization credentials ... aborting" && exit 123 ;;
                   403) echo "The client is not authorized to invoke the service ... aborting" && exit 123 ;;
                   422) echo "System limit reached ... aborting" && exit 123 ;;
                   502) echo "Gateway unavailable to process request ... aborting" && exit 123 ;;
                   503) echo "Service is temporarily unavailable ... aborting" && exit 123 ;;
                   *)   echo "$status!!  Activation: status not defined, confirm if activation was successful in control centre ... aborting" && exit 123 ;;
                esac
             fi
             if [[ $line =~ "error code" ]] ; then
               echo "${line}" && exit 123
             fi
           done
fi
