# Usage: ruby tests/test_solutions.rb <language_slug>
#
ENV["DOCKER_BUILDKIT"] = "0"

require_relative "../lib/solution_tester"
require_relative "../lib/models"

course = Course.load_from_file("../course-definition.yml")

language_slug = ARGV[0]

stage_slugs = if ARGV[1]
  ARGV[1].split(",")
else
  course.stages.map(&:slug)
end

language = Language.find_by_slug!(language_slug)

tester = SolutionTester.new(course, language, stage_slugs)
tester.test || exit(1)
