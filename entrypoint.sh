#!/bin/bash
#set -e
set -o pipefail

# Create /root/.edgerc file from env variable
echo -e "${EDGERC}" > ~/.edgerc

#  Set Variables
edgeworkersName=$1
network=$2

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
if [ -z "$edgeworkersID" ]; then
    edgeworkersgroupID="93068"
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
