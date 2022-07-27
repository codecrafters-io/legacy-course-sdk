require "octokit"
require "tmpdir"

require_relative "../lib/pull_request_generator"

pull_request_generator = PullRequestGenerator.new(
  course: Course.load_from_file("../course-definition.yml"),
  solutions_directory: "../solutions"
)

pull_request_generator.generate_all
