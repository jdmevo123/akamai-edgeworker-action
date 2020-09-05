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
edgeworkersID=$(echo ${edgeworkerList} | jq --arg edgeworkersName "${edgeworkersName}" '.data[] | select(.name == $edgeworkersName) | .edgeWorkerId')
edgeworkersgroupIude=$(echo $edgeworkerList | jq --arg edgeworkersName "$edgeworkersName" '.data[] | select(.name == $edgeworkersName) | .groupId')
cd $GITHUB_WORKSPACE

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
# pack optional JS libriries if exist 
if [ -d $utilitiesDir ] ; then 
  tarCommand=${tarCommand}" $utilitiesDir"
fi
# execute tar command
eval $tarCommand
if [ "$?" -ne "0" ]
then
  echo "ERROR: tar command failed" 
  exit 123
fi

if [ -n "$edgeworkersID" ]; then
   echo "Uploading Edgeworker Version"
   #UPLOAD edgeWorker
   ewupload=$(akamai edgeworkers upload \
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
         ${edgeworkersVersion} |
           while read line; do
             if [[ $line =~ status ]] ; then
                status=`echo $line | tr -d -c 0-9`
                case $status in
                   200) echo "Activation Successfull" ;;
                   201) echo "Activation Successfull" ;;
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
               echo $line && exit 123
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
         ${edgeworkersVersion} |
           while read line; do
             if [[ $line =~ status ]] ; then
                status=`echo $line | tr -d -c 0-9`
                case $status in
                   200) echo "Activation Successfull" ;;
                   201) echo "Activation Successfull" ;;
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
               echo $line && exit 123
             fi
           done
fi
