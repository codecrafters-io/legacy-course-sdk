This repository is used to develop & test CodeCrafters courses.

## Setup

Make sure that you have Docker installed.

## Developing Courses

We'll use [`build-your-own-git`](https://github.com/codecrafters-io/build-your-own-git) as an example here.

Clone this repository:

```sh
git clone https://github.com/codecrafters-io/course-sdk.git && cd course-sdk
```

Clone the course repository into `courses/build-your-own-git`:

```sh
git clone https://github.com/codecrafters-io/build-your-own-git.git courses/build-your-own-git
```

Run this command to compile and test Go solutions:

```sh
docker compose run tester scripts/compile_and_test.sh courses/build-your-own-git go
```

If you only want to test solutions for specific stage(s):

```sh
docker compose run tester scripts/compile_and_test.sh courses/build-your-own-git go stage_slug_1,stage_slug_2
```

If you're running an older version of Docker, use `docker-compose` instead of `docker compose`.
