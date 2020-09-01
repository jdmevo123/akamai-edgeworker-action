FROM akamai/akamai-docker

LABEL "com.github.actions.name"="Akamai Edgeworkers"
LABEL "com.github.actions.description"="Deploy Edgeworkers via the Akamai API's"
LABEL "com.github.actions.icon"="trash-2"
LABEL "com.github.actions.color"="orange"

LABEL version="0.1.0"
LABEL repository="https://github.com/jdmevo123/akamai-edgeworker-action"
LABEL homepage=""
LABEL maintainer="Dale Lenard <dale_lenard@outlook.com>"

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
