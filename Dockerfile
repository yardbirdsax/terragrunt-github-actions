FROM alpine:3

RUN ["/bin/sh", "-c", "apk add --update --no-cache bash ca-certificates curl git jq openssh python3 py3-pip uuidgen"]
# RUN ["pip", "install", "PyYAML==6.0"]
RUN ["/bin/sh", "-c", "git clone https://github.com/yaml/pyyaml.git && cd pyyaml && git checkout release/5.4.1 && sed -i.bak 's/Cython/Cython<3.0/g' pyproject.toml && python setup.py sdist && pip install --pre dist/PyYAML-5.4.1.tar.gz"]

## Addresses https://avd.aquasec.com/nvd/cve-2022-40674
RUN apk add --no-cache expat>2.4.9-r0

COPY ["src", "/src/"]

ENTRYPOINT ["/src/main.sh"]
