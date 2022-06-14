# Usage: ruby tests/test_solutions.rb <language_slug>
#
ENV["DOCKER_BUILDKIT"] = "0"

require_relative "../lib/solution_tester"
require_relative "../lib/models"

language_slug = ARGV[0]

course = Course.load_from_file("../course-definition.yml")
language = Language.find_by_slug!(language_slug)

tester = SolutionTester.new(course, language)
tester.test || exit(1)
