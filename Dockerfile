FROM ubuntu:22.04

RUN apt-get update

RUN apt-get install -y curl
RUN apt-get install -y make
RUN apt-get install -y ruby-full
RUN apt-get install -y git
RUN apt-get install -y patchutils

RUN curl -fsSL get.docker.com -o /tmp/get-docker.sh && sh /tmp/get-docker.sh
RUN curl -sfLS install-node.vercel.app/v16.13.2 | bash -s -- --yes
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