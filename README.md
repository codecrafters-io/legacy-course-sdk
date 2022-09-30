This repository is used to develop & test CodeCrafters courses.

## Setup

Make sure that you have Docker installed.

## Developing Courses

We'll use [`build-your-own-git`](https://github.com/codecrafters-io/build-your-own-git) as an example here.

Clone the course repository into `courses/git`: 

```sh
$ git clone git@github.com:codecrafters-io/build-your-own-git.git courses/git
```

Run this command to compile and test Go solutions: 

```sh
$ docker-compose run development scripts/compile_and_test.rb courses/git go
```