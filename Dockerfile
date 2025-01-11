FROM alpine:3.21.0

LABEL maintainer="CoMfUcIoS"

RUN apk update
RUN apk add curl unzip

RUN curl -sSL https://cli.openfaas.com | sh

RUN wget https://get.opentofu.org/install-opentofu.sh -O install-opentofu.sh && \
  chmod +x install-opentofu.sh && \
  ./install-opentofu.sh --install-method apk && \
  rm -f install-opentofu.sh

WORKDIR /work

COPY . .
