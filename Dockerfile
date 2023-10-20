FROM ubuntu:22.04

RUN apt-get update

RUN apt-get install -y build-essential
RUN apt-get install -y curl
RUN apt-get install -y make
RUN apt-get install -y ruby-full
RUN apt-get install -y git
RUN apt-get install -y patchutils
RUN apt-get install -y ca-certificates
RUN apt-get install -y gnupg

RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update
RUN apt-get install -y nodejs

RUN curl -fsSL https://get.docker.com -o /tmp/get-docker.sh && sh /tmp/get-docker.sh

# Install gems
RUN gem install bundler

WORKDIR /course-sdk

# Ensure that node_modules isn't overriden as part of docker mount
ADD package.json /node-app/package.json
ADD package-lock.json /node-app/package-lock.json
RUN cd /node-app && npm install
ENV PATH="/node-app/node_modules/.bin:${PATH}"

ADD Gemfile /course-sdk/Gemfile
ADD Gemfile.lock /course-sdk/Gemfile.lock
RUN bundle install

ADD . /course-sdk