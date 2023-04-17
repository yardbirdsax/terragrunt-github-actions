FROM alpine:3

RUN ["/bin/sh", "-c", "apk add --update --no-cache bash ca-certificates curl git jq openssh python3 py3-pip uuidgen docker"]
RUN ["pip", "install", "PyYAML==6.0"]

## Addresses https://avd.aquasec.com/nvd/cve-2022-40674
RUN apk add --no-cache expat>2.4.9-r0

COPY ["src", "/src/"]

ENTRYPOINT ["/src/main.sh"]
