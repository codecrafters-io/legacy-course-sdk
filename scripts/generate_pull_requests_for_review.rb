require "octokit"
require "tmpdir"

require_relative "../lib/pull_request_generator"

pull_request_generator = PullRequestGenerator.new(
  course: Course.load_from_dir(ARGV[0]),
  solutions_directory: File.join(ARGV[0], "solutions"),
)

pull_request_generator.generate_all
