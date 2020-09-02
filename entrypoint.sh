#!/bin/bash
set -o pipefail

# Create /root/.edgerc file from env variable
echo -e "${EDGERC}" > ~/.edgerc

#  Set Variables
edgeworkersName=$1
network=$2
groupid=$3

echo ${edgeworkersName}
response=$(akamai edgeworkers list-ids --json --section edgeworkers --edgerc ~/.edgerc)
edgeworkerList=$( cat ${response} )
echo ${edgeworkerList}
edgeworkersID=$(echo ${edgeworkerList} | jq --arg edgeworkersName "${edgeworkersName}" '.data[] | select(.name == $edgeworkersName) | .edgeWorkerId')
echo $edgeworkersID
edgeworkersgroupIude=$(echo $edgeworkerList | jq --arg edgeworkersName "$edgeworkersName" '.data[] | select(.name == $edgeworkersName) | .groupId')
echo $edgeworkersgroupID
echo $edgeworkersID
echo $edgeworkersgroupID
cd $GITHUB_WORKSPACE
tar -czvf ~/deploy.tar.gz main.js bundle.json utils

if [ -n "$edgeworkersID" ]; then
   echo "Uploading Edgeworker Version"
   #UPLOAD edgeWorker
   akamai edgeworkers upload \
     --edgerc ~/.edgerc \
     --section edgeworkers \
     --bundle ~/deploy.tar.gz \
     ${edgeworkersID} |
         while read line; do
             if [[ $line =~ status ]] ; then
                status=`echo $line | tr -d -c 0-9`
                case $status in
                   200) echo "Activation Successfull" ;;
                   201) edgeworkersVersion=$(echo $(<$GITHUB_WORKSPACE/bundle.json) | jq '.["edgeworker-version"]' | tr -d '"')
                        echo "Activating Edgeworker Version: ${edgeworkersVersion}"
                        #ACTIVATE  edgeworker
                        echo "activating"
                        akamai edgeworkers activate \
                              --edgerc ~/.edgerc \
                              --section edgeworkers \
                              ${edgeworkersID} \
                              ${network} \
                              ${edgeworkersVersion} |
                                while read line; do
                                  if [[ $line =~ status ]] ; then
                                     status=`echo $line | tr -d -c 0-9`
                                     case $status in
                                        200) echo "Activation Successfull" ;;
                                        201) echo "Activation Successfull" ;;
                                        400) echo "Previous activation still pending ... aborting" && exit 1 ;;
                                        401) echo "Invalid authorization credentials ... aborting" && exit 1 ;;
                                        403) echo "The client is not authorized to invoke the service ... aborting" && exit 1 ;;
                                        422) echo "System limit reached ... aborting" && exit 1 ;;
                                        502) echo "Gateway unavailable to process request ... aborting" && exit 1 ;;
                                        503) echo "Service is temporarily unavailable ... aborting" && exit 1 ;;
                                        *)   echo "$status!!  Activation: status not defined ... aborting" && exit 1 ;;
                                     esac
                                  fi
                                done ;;
                   400) echo "Previous activation still pending ... aborting" && exit 1 ;;
                   401) echo "Invalid authorization credentials ... aborting" && exit 1 ;;
                   403) echo "The client is not authorized to invoke the service ... aborting" && exit 1 ;;
                   422) echo "System limit reached ... aborting" && exit 1 ;;
                   502) echo "Gateway unavailable to process request ... aborting" && exit 1 ;;
                   503) echo "Service is temporarily unavailable ... aborting" && exit 1 ;;
                   *)   echo "$status!!  Activation: status not defined ... aborting" && exit 1 ;;
                esac
             fi
           done
fi
if [ -z "$edgeworkersID" ]; then
    edgeworkersgroupID=${groupid}
    # Register ID
    edgeworkerList=$(cat $(akamai edgeworkers register \
                      --json --section edgeworkers \
                      --edgerc ~/.edgerc  \
                      ${edgeworkersgroupID} \
                      ${edgeworkersName}))
    echo ${edgeworkerList}
    echo "edgeworker registered"
    edgeworkersID=$(echo ${edgeworkerList} | jq '.data[] | .edgeWorkerId')
    edgeworkersgroupID=$(echo ${edgeworkerList} | jq '.data[] | .groupId')
    echo ${edgeworkersID}
    echo "Uploading Edgeworker Version"
    #UPLOAD edgeWorker
    uploadreponse=$(akamai edgeworkers upload \
      --edgerc ~/.edgerc \
      --section edgeworkers \
      --bundle ~/deploy.tar.gz \
      ${edgeworkersID})
    edgeworkersVersion=$(echo $(<$GITHUB_WORKSPACE/bundle.json) | jq '.["edgeworker-version"]' | tr -d '"')
    echo "Activating Edgeworker Version: ${edgeworkersVersion}"
    #ACTIVATE  edgeworker
    echo "activating"
    akamai edgeworkers activate \
    --edgerc ~/.edgerc \
    --section edgeworkers \
    ${edgeworkersID} \
    ${network} \
    ${edgeworkersVersion}
fi
