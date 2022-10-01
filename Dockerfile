FROM ubuntu:22.04

RUN apt-get update

RUN apt-get install -y curl
RUN apt-get install -y make
RUN apt-get install -y ruby-full

RUN curl -fsSL get.docker.com -o /tmp/get-docker.sh && sh /tmp/get-docker.sh
RUN curl -sfLS install-node.vercel.app/v16.13.2 | bash -s -- --yes
RUN gem install bundler

WORKDIR /course-sdk

ADD Gemfile /course-sdk/Gemfile
ADD Gemfile.lock /course-sdk/Gemfile.lock
RUN bundle install

ADD package.json /course-sdk/package.json
ADD package-lock.json /course-sdk/package-lock.json
RUN npm install

ADD . /course-sdk