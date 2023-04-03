FROM alpine:3

RUN ["/bin/sh", "-c", "apk add --update --no-cache bash ca-certificates curl git jq openssh python3 py3-pip uuidgen"]
RUN ["pip", "install", "PyYAML==6.0"]
ENV PATH="/root/.tfenv/bin:${PATH}"
RUN mkdir -p ~/.tfenv && \
    cd ~/.tfenv && \
    git init && \
    git remote add origin https://github.com/tfutils/tfenv && \
    git fetch origin v3.0.0 --depth=1 && \
    git checkout FETCH_HEAD
## Addresses https://avd.aquasec.com/nvd/cve-2022-40674
RUN apk add --no-cache expat>2.4.9-r0

COPY ["src", "/src/"]
RUN for tfver in $(cat /src/terraform-versions); do tfenv install "${tfver}"; done

ENTRYPOINT ["/src/main.sh"]
