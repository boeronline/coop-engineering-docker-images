# syntax=docker/dockerfile:1.3
FROM docker.io/safewaters/docker-lock:latest@sha256:432d90ddc2891f4845241adc63e5eef2dd1486fa14ea7882433cbd3f8ed64622 AS docker-lock
FROM ghcr.io/terraform-linters/tflint-bundle:v0.48.0.0@sha256:523a85b4bf7af415cbb5f53ac1b56cd7501c8c8125f96c5b5cc19c895d894513 AS tflint
FROM docker.io/aquasec/trivy:0.56.2@sha256:26245f364b6f5d223003dc344ec1eb5eb8439052bfecb31d79aeba0c74344b3a AS trivy
FROM docker.io/bitnami/oras:1.2.0@sha256:efd73d06d907f5efd1ba4eddd00aff67b6e22590366d19a7dc5de3b3ab6da9ad AS oras
FROM docker.io/hashicorp/terraform:1.9.8@sha256:18f9986038bbaf02cf49db9c09261c778161c51dcc7fb7e355ae8938459428cd AS terraform
FROM quay.io/terraform-docs/terraform-docs:0.19.0@sha256:d91005e55ad9e2f5a1c9cd7c78520414615ec150c922575887e94f5f5fe26c66 AS tfdocs
FROM docker.io/library/golang:1.23.2@sha256:ad5c126b5cf501a8caef751a243bb717ec204ab1aa56dc41dc11be089fafcb4f AS golang

RUN \
    go env > /usr/local/bin/goenv.sh && \
    true

FROM docker.io/library/ubuntu:24.04@sha256:99c35190e22d294cdace2783ac55effc69d32896daaa265f0bbedbcde4fbe3e5 AS base


# https://packages.ubuntu.com/search?keywords=busybox&searchon=names&suite=focal&section=all
RUN \
    apt-get update && \
    apt-get install -y \
        --no-install-recommends \
        busybox \
        ca-certificates \
        curl \
        git \
        make \
        socat \
        && \
    rm -vr /var/lib/apt/lists/* && \
    true

VOLUME /srv/workspace
WORKDIR /srv/workspace

ARG tfswitcher_version=0.13.1300

COPY --from=terraform /bin/terraform /usr/bin/terraform
COPY --from=tflint /root/.tflint.d /root/.tflint.d
COPY --from=tflint /usr/local/bin/tflint /usr/bin/tflint
COPY --from=trivy  /usr/local/bin/trivy /usr/local/bin/trivy
COPY --from=golang /usr/local/bin/goenv.sh /usr/local/bin/goenv.sh
COPY --from=docker-lock /prod/docker-lock /usr/local/bin/docker-lock
COPY --from=tfdocs /usr/local/bin/terraform-docs /usr/local/bin/terraform-docs
COPY --from=oras /oras /usr/local/bin/oras

COPY terraform-switcher_${tfswitcher_version}_checksums.txt /var/tmp/terraform-switcher_${tfswitcher_version}_checksums.txt


ARG terraform_versions="0.15.5 1.0.11 1.1.7"

RUN \
    mkdir -vp ~/.cache ~/.local/bin ~/bin && \
    true

RUN \
    cd /var/tmp && \
    . /usr/local/bin/goenv.sh && \
    curl -LOJ "https://github.com/warrensbox/terraform-switcher/releases/download/${tfswitcher_version}/terraform-switcher_${tfswitcher_version}_${GOOS}_${GOARCH}.tar.gz" && \
    sed -i "/_${GOOS}_${GOARCH}.tar.gz/!d" "terraform-switcher_${tfswitcher_version}_checksums.txt" && \
    sha256sum -c "terraform-switcher_${tfswitcher_version}_checksums.txt" && \
    tar -xvf "terraform-switcher_${tfswitcher_version}_${GOOS}_${GOARCH}.tar.gz" -C /usr/local/bin tfswitch && \
    # mkdir -vp ~/.cache/.terraform.versions && \
    # ln -s ~/.cache/.terraform.versions ~/.terraform.versions && \
    # for ver in ${terraform_versions}; \
    # do \
    #     tfswitch "${ver}"; \
    # done; \
    true

ENV TF_PLUGIN_CACHE_DIR=/root/.cache/terraform.d/plugin-cache
ENV TRIVY_CHECKS_DB=ghcr.io/aquasecurity/trivy-checks:1
ENV TRIVY_CACHE_DIR=/root/.cache/trvy


COPY maker /usr/local/bin/maker
RUN \
    ln -rs /usr/local/bin/maker /usr/local/bin/help && \
    ln -rs /usr/local/bin/maker /usr/local/bin/validate && \
    ln -rs /usr/local/bin/maker /usr/local/bin/validate-fix && \
    ln -rs /usr/local/bin/maker /usr/local/bin/terraform-reinit && \
    ln -rs /usr/local/bin/maker /usr/local/bin/terraform-upgrade && \
    ln -rs /usr/local/bin/maker /usr/local/bin/terraform-relock && \
    ln -rs /usr/local/bin/maker /usr/local/bin/tf-docs && \
    true

COPY Makefile /usr/local/share/devtools-terraform/Makefile

RUN git config --system --add safe.directory /srv/workspace

# Include the current version of trivy checks db in the image
SHELL ["/bin/bash", "-exo", "pipefail", "-c"]
RUN DIGEST=$(oras pull $TRIVY_CHECKS_DB | grep Digest | cut -d' ' -f2) && \
    mv bundle.tar.gz /var/trivy-checks-db.tar.gz && \
    DOWNLOADED_AT=$(date +"%Y-%m-%dT%H:%M:%S.%6N%:z") && \
    echo "{\"Digest\":\"$DIGEST\",\"DownloadedAt\":\"$DOWNLOADED_AT\"}" > /var/trivy-checks-metadata.json


CMD ["validate"]
