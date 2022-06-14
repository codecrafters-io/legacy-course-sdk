redis_tester_api_url = "https://api.github.com/repos/codecrafters-io/redis-tester/releases/latest"
docker_tester_api_url = "https://api.github.com/repos/codecrafters-io/docker-tester/releases/latest"
git_tester_api_url = "https://api.github.com/repos/codecrafters-io/git-tester/releases/latest"
#react_tester_api_url = "https://api.github.com/repos/codecrafters-io/react-tester/releases/latest"
sqlite_tester_api_url = "https://api.github.com/repos/codecrafters-io/sqlite-tester/releases/latest"

latest_redis_tester_version = $(shell curl $(redis_tester_api_url) | jq -r ".tag_name")
latest_docker_tester_version = $(shell curl $(docker_tester_api_url) | jq -r ".tag_name")
latest_git_tester_version = $(shell curl $(git_tester_api_url) | jq -r ".tag_name")
#latest_react_tester_version = $(shell curl $(react_tester_api_url) | jq -r ".tag_name")
latest_sqlite_tester_version = $(shell curl $(sqlite_tester_api_url) | jq -r ".tag_name")

compile: compile_starters compile_first_stage_solutions compile_solution_diffs

compile_starters:
	rm -rf ../compiled_starters/*
	bundle exec ruby scripts/compile_starters.rb

compile_first_stage_solutions:
	bundle exec ruby scripts/compile_first_stage_solutions.rb

compile_solution_diffs:
	bundle exec ruby scripts/compile_solution_diffs.rb

download_testers:
	mkdir -p .testers
	test -d .testers/docker || make download_docker_tester
	test -d .testers/git || make download_git_tester
	# test -d .testers/react || make download_react_tester
	test -d .testers/redis || make download_redis_tester
	test -d .testers/sqlite || make download_sqlite_tester

download_redis_tester:
	curl --fail -Lo .testers/redis.tar.gz https://github.com/codecrafters-io/redis-tester/releases/download/$(latest_redis_tester_version)/$(latest_redis_tester_version)_linux_amd64.tar.gz
	mkdir .testers/redis
	tar xf .testers/redis.tar.gz -C .testers/redis
	rm .testers/redis.tar.gz

download_docker_tester:
	curl --fail -Lo .testers/docker.tar.gz https://github.com/codecrafters-io/docker-tester/releases/download/$(latest_docker_tester_version)/$(latest_docker_tester_version)_linux_amd64.tar.gz
	mkdir .testers/docker
	tar xf .testers/docker.tar.gz -C .testers/docker
	rm .testers/docker.tar.gz

download_git_tester:
	curl --fail -Lo .testers/git.tar.gz https://github.com/codecrafters-io/git-tester/releases/download/$(latest_git_tester_version)/$(latest_git_tester_version)_linux_amd64.tar.gz
	mkdir .testers/git
	tar xf .testers/git.tar.gz -C .testers/git
	rm .testers/git.tar.gz

#download_react_tester:
#	curl --fail -Lo .testers/react.tar.gz https://github.com/codecrafters-io/react-tester/releases/download/$(latest_react_tester_version)/$(latest_react_tester_version)_linux_amd64.tar.gz
#	mkdir .testers/react
#	tar xf .testers/react.tar.gz -C .testers/react
#	rm .testers/react.tar.gz

download_sqlite_tester:
	curl --fail -Lo .testers/sqlite.tar.gz https://github.com/codecrafters-io/sqlite-tester/releases/download/$(latest_sqlite_tester_version)/$(latest_sqlite_tester_version)_linux_amd64.tar.gz
	mkdir .testers/sqlite
	tar xf .testers/sqlite.tar.gz -C .testers/sqlite
	rm .testers/sqlite.tar.gz
