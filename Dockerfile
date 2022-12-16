FROM alpine:3

RUN ["/bin/sh", "-c", "apk add --update --no-cache bash ca-certificates curl git jq openssh uuidgen"]

## Addresses https://avd.aquasec.com/nvd/cve-2022-40674
RUN apk add --no-cache expat>2.4.9-r0

RUN ln -s /usr/local/bin/docker $HOME/bin/docker

COPY ["src", "/src/"]

ENTRYPOINT ["/src/main.sh"]
