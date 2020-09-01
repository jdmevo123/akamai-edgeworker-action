#!/bin/bash
#set -e
set -o pipefail

# Create /root/.edgerc file from env variable
echo -e "${EDGERC}" > ~/.edgerc

#copy files to container
echo $GITHUB_WORKSPACE
# cat $GITHUB_WORKSPACE/main.js
# ls $GITHUB_WORKSPACE
mkdir ~/deploy
mkdir ~/deploy/utils
echo $GITHUB_WORKSPACE/main.js > ~/deploy/main.js
echo $GITHUB_WORKSPACE/bundle.json > ~/deploy/bundle.json
for file in $GITHUB_WORKSPACE/utils/
do
   echo "$file" >> ~/deploy/utils/"$file"
done

#  Set Variables
edgeworkersName=$1
network=$2

echo ${edgeworkersName}
edgeworkerList=$(cat $(akamai edgeworkers list-ids --json --section edgeworkers --edgerc ~/.edgerc))
echo ${edgeworkerList}
edgeworkersID=$(echo ${edgeworkerList} | jq --arg edgeworkersName "${edgeworkersName}" '.data[] | select(.name == $edgeworkersName) | .edgeWorkerId')
echo $edgeworkersID
edgeworkersgroupIude=$(echo $edgeworkerList | jq --arg edgeworkersName "$edgeworkersName" '.data[] | select(.name == $edgeworkersName) | .groupId')
echo $edgeworkersgroupID
echo $edgeworkersID
echo $edgeworkersgroupID
cd ~/deploy
tar -czvf ~/deploy.tar.gz main.js bundle.json utils

if [ -n "$edgeworkersID" ]; then
   echo "Uploading Edgeworker Version"
   #UPLOAD edgeWorker
   uploadreponse=$(akamai edgeworkers upload \
     --edgerc ~/.edgerc \
     --section edgeworkers \
     --bundle ~/deploy.tar.gz \
     ${edgeworkersID})
   edgeworkersVersion=$(echo $(<~/deploy/bundle.json) | jq '.["edgeworker-version"]' | tr -d '"')
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
    edgeworkersVersion=$(echo $(<~/deploy/bundle.json) | jq '.["edgeworker-version"]' | tr -d '"')
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
