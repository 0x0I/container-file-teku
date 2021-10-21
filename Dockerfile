ARG build_version="openjdk:17.0.1-slim-buster"
ARG teku_version=21.10.1
ARG build_type="source"

# ******* Stage: builder ******* #
FROM ${build_version} as builder-source

ARG teku_version

RUN apt update && apt install --yes --no-install-recommends git

WORKDIR /tmp
RUN git clone --depth 1 --branch ${teku_version} https://github.com/Consensys/teku.git

RUN cd teku && ./gradlew distTar installDist
RUN mkdir /install && cp -r /tmp/teku/build/install/teku/* /install

FROM ${build_version} as builder-package

ARG teku_version

RUN apt update && apt install --yes --no-install-recommends curl ca-certificates

RUN mkdir /install && curl -L https://artifacts.consensys.net/public/teku/raw/names/teku.tar.gz/versions/${teku_version}/teku-${teku_version}.tar.gz -o teku.tar.gz && \
		tar xzf teku.tar.gz -C /install --strip-components 1

FROM builder-${build_type} as build-condition

FROM ${build_version} as base

COPY --from=build-condition /install /usr/local/teku

RUN apt update && apt install --yes --no-install-recommends \
    ca-certificates \
    curl \
    python3-pip \
    tini \
    # apt cleanup
	&& apt-get autoremove -y; \
	apt-get clean; \
	update-ca-certificates; \
	rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

WORKDIR /docker-entrypoint.d
COPY entrypoints /docker-entrypoint.d
COPY scripts/entrypoint.sh /usr/local/bin/teku-entrypoint

COPY scripts/teku-helper.py /usr/local/bin/teku-helper
RUN chmod 775 /usr/local/bin/teku-helper

RUN pip3 install click requests pyaml

ENTRYPOINT ["teku-entrypoint"]

# ******* Stage: testing ******* #
FROM base as test

ENV PATH="/usr/local/teku/bin:${PATH}"

ARG goss_version=v0.3.16

RUN curl -fsSL https://goss.rocks/install | GOSS_VER=${goss_version} GOSS_DST=/usr/local/bin sh

WORKDIR /test

COPY test /test

CMD ["goss", "--gossfile", "/test/goss.yaml", "validate"]

# ******* Stage: release ******* #
FROM base as release

ARG version=0.1.0

ENV PATH="/usr/local/teku/bin:${PATH}"

LABEL 01labs.image.authors="zer0ne.io.x@gmail.com" \
	01labs.image.vendor="O1 Labs" \
	01labs.image.title="0labs/teku" \
	01labs.image.description="Open-source Ethereum 2.0 client written in Java" \
	01labs.image.source="https://github.com/0x0I/container-file-teku/blob/${version}/Dockerfile" \
	01labs.image.documentation="https://github.com/0x0I/container-file-teku/blob/${version}/README.md" \
	01labs.image.version="${version}"

#       p2p/tcp   p2p/udp   api   metrics
#          ↓         ↓       ↓      ↓
EXPOSE 9000/tcp   9000/udp  5051   8008

CMD ["teku"]
