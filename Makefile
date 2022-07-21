course_repository_name = $(shell basename $(shell dirname $(shell pwd)))
course_slug = $(shell echo $(course_repository_name) | rev | cut -d- -f1 | rev)
tester_api_url = "https://api.github.com/repos/codecrafters-io/$(course_slug)-tester/releases/latest"
latest_tester_version = $(shell curl $(tester_api_url) | jq -r ".tag_name")

compile: compile_starters compile_first_stage_solutions compile_solution_diffs compile_solution_definitions

compile_starters:
	rm -rf ../compiled_starters/*
	bundle exec ruby scripts/compile_starters.rb

compile_first_stage_solutions:
	bundle exec ruby scripts/compile_first_stage_solutions.rb

compile_solution_definitions:
	bundle exec ruby scripts/compile_solution_definitions.rb

compile_solution_diffs:
	bundle exec ruby scripts/compile_solution_diffs.rb

download_testers:
	mkdir -p .testers
	test -d .testers/$(course_slug) || make download_tester

download_tester:
	curl --fail -Lo .testers/$(course_slug).tar.gz https://github.com/codecrafters-io/$(course_slug)-tester/releases/download/$(latest_tester_version)/$(latest_tester_version)_linux_amd64.tar.gz
	mkdir .testers/$(course_slug)
	tar xf .testers/$(course_slug).tar.gz -C .testers/$(course_slug)
	rm .testers/$(course_slug).tar.gz
