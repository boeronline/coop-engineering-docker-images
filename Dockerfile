FROM docker.io/safewaters/docker-lock:0.8.10@sha256:e87cfa64db3ceb8e5d14ec41136b068e2335fdcdfbb890fa20dd091e82735d04 as docker-lock
FROM docker.io/hadolint/hadolint:v2.10.0@sha256:93f0afd12c3be5d732227c0226dd8e7bb84f79319a773d7f8519e55f958ba415 as hadolint
FROM docker.io/goodwithtech/dockle:v0.4.6@sha256:534ecfe2204403e1b563d61b255ddd4762b20c9d72ce7af239fb1135be6c9569 as dockle
FROM docker.io/library/python:3.10.6@sha256:cbf49327fae903d64ab28251912fc00faea2c1baee493d347a07973a2cb50f98 as python

FROM python as devtools

RUN \
    apt update && \
    apt-get install -y \
        docker \
    && true

RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -

RUN python -m ensurepip

ENV PATH=/root/.poetry/bin:$PATH

WORKDIR /tmp/workspace
COPY pyproject.toml poetry.toml ./
RUN poetry install
