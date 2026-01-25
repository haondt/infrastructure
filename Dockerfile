FROM alpine:3.21

RUN apk add --no-cache \
    ansible \
    make \
    openssh-client \
    bash \
    curl \
    git \
    py3-yaml \
    py3-jinja2

ARG YQ_VERSION=v4.34.2
ARG YQ_BINARY=yq_linux_amd64
RUN wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}.tar.gz -O - |\
  tar xz && mv ${YQ_BINARY} /usr/local/bin/yq

ARG KUBECTL_VERSION=v1.34.0
RUN curl -sSL -o /usr/local/bin/kubectl https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
  && chmod +x /usr/local/bin/kubectl

