FROM ubuntu:22.04

RUN apt update

RUN apt install -y ruby-full
RUN apt install -y curl

RUN curl -sfLS install-node.vercel.app/v16.13.2 | bash -s -- --yes
RUN gem install bundler

ADD . /course-sdk
WORKDIR /course-sdk

RUN bundle install
RUN npm install