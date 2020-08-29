#!/bin/sh -l
set -e
set -o pipefail

# Create /root/.edgerc file from env variable
echo -e "${EDGERC}" > /root/.edgerc

# List Edgeworkers and identify if existing
_edgeworkersID=akamai edgeworkers list-ids | jq 'select(.edgeWorkerIds.name == ${_edgeworker-name}) | .edgeWorkerId'
if [ -n "${_edgeworkersID}" ]; then
   # Upload Version
    akamai edgeworkers upload \
      --edgerc /root/.edgerc \
      --section edgeworkers \
      --codeDir /. \
      ${_edgeworkersID}
   # Activate Edgeworker
    akamai edgeworkers activate \
    --edgerc /root/.edgerc \
    --section edgeworkers \
    ${_edgeworker-id} \
    ${_NETWORK} \
    <version-identifier>
fi
if [ -z "${_edgeworkersID}" ]; then
  # Register ID
    _edgeworkersID=akamai edgeworkers register \
      --edgerc /root/.edgerc \
      --section edgeworkers \
      ${_GROUP} \
      ${_edgeworker-name} | jq '.edgeWorkerId' 
fi
