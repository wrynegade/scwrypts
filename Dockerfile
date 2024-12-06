#####################################################################

FROM ubuntu:latest AS scwrypts

ARG SCWRYPTS_ENV=ci.github-actions

ENV KUBEVAL_VERSION=0.15.0
ENV DEBIAN_FRONTEND=noninteractive
ENV CI=true
ENV SCWRYPTS_PLUGIN_ENABLED__ci=1

RUN apt-get update && apt-get install --yes \
    curl \
    unzip \
    zsh \
    fzf \
    ripgrep \
    curl \
    git \
    sudo \
	pip \
	npm \
	docker.io \
	uuid-runtime \
	bsdmainutils \
    && apt-get clean

# Download and install kubeval
RUN curl -L -o /tmp/kubeval.tar.gz https://github.com/instrumenta/kubeval/releases/download/${KUBEVAL_VERSION}/kubeval-linux-amd64.tar.gz \
    && tar -xzf /tmp/kubeval.tar.gz -C /usr/local/bin \
    && rm /tmp/kubeval.tar.gz

WORKDIR /workspace

COPY . /opt/scwrypts

ENV PATH="/opt/scwrypts:$PATH"

#RUN /opt/scwrypts/scwrypts -v 4 \
#    --name scwrypts/virtualenv/update-all \
#    --group scwrypts \
#    --type zsh

ENTRYPOINT ["/opt/scwrypts/scwrypts"]

CMD ["--help"]
