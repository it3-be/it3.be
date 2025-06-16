# Dockerfile to build/generate web-site www.it3.be
# docker build -t jekyll --build-arg local_user=gdha --build-arg local_id=1000 .

# docker: Error response from daemon: Mounts denied: 
# The path /projects/web/it3.be is not shared from the host and is not known to Docker.
# You can configure shared paths from Docker -> Preferences... -> Resources -> File Sharing.

# docker run -it -v /projects/web/it3.be:/home/gdha/projects/web/it3.be  -v /home/gdha/.netrc:/home/gdha/.netrc \
# -v /home/gdha/.gitconfig:/home/gdha/.gitconfig -v /home/gdha/.ssh:/home/gdha/.ssh \
# -v /home/gdha/.gnupg:/home/gdha/.gnupg  --net=host jekyll

# Afterwards we can just start the container as:
# docker start -i jekyll

FROM ubuntu:24.04
ARG local_user=gdha
ARG local_id=1000
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    ruby-full \
    ruby-dev \
    rubygems-integration \
    make \
    gcc \
    curl \
    ca-certificates \
    git \
    openssh-client \
    gnupg \
    locales \
    lftp \
    vim \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# install ruby gems
RUN gem install jekyll --version="~> 4.2.0" \
    && gem install redcarpet \
    && gem install therubyracer

# useradd: UID 1000 is not unique issue - to fix read https://askubuntu.com/questions/1513927/ubuntu-24-04-docker-images-now-includes-user-ubuntu-with-uid-gid-1000
#RUN useradd -u ${local_id} ${local_user} && \
#    mkdir -p /home/${local_user}/www.it3.be && \
#    chown -R ${local_user}:${local_user} /home/${local_user}

RUN usermod -l ${local_user}  ubuntu && \
    groupmod  --new-name ${local_user} ubuntu && \
    mkdir -p /home/${local_user}/projects/web/it3.be && \
    chown -R ${local_user}:${local_user} /home/${local_user}

# Needed to make nerdtree plugin for vim work
RUN locale-gen en_US.UTF-8 && \
    echo "export LC_CTYPE=en_US.UTF-8" >> /home/${local_user}/.bashrc && \
    echo "export LC_ALL=en_US.UTF-8" >> /home/${local_user}/.bashrc

WORKDIR /home/${local_user}/projects/web/it3.be
USER ${local_user}
