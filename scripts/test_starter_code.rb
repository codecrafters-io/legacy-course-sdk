# Usage: ruby tests/test_starter_code.rb <language>
ENV["DOCKER_BUILDKIT"] = "0"

require_relative "../lib/dockerfile_tester"
require_relative "../lib/starter_repo_tester"
require_relative "../lib/models"

course = Course.load_from_file("../course-definition.yml")

DOCKERFILE_PATHS_TO_SKIP = [
  "rust-1.43.Dockerfile", # Newer dependencies aren't compatible
  "rust-1.54.Dockerfile", # Newer dependencies aren't compatible
  "haskell-8.8.Dockerfile" # Newer dependencies aren't compatible
]

STARTER_REPO_PATHS_TO_SKIP = [
  "compiled_starters/redis-starter-elixir" # Temporarily disabled, triggers timeout
]

language_filter = ARGV[0]

dockerfile_testers = Dir["../dockerfiles/*.Dockerfile"].map do |path|
  next if DOCKERFILE_PATHS_TO_SKIP.include?(path)
  DockerfileTester.from_dockerfile(course, File.basename(path))
end.compact

starter_repo_testers = Dir["../compiled_starters/*"].map do |compiled_starter_path|
  next if STARTER_REPO_PATHS_TO_SKIP.include?(compiled_starter_path)
  repo_name = File.basename(compiled_starter_path)
  StarterRepoTester.from_repo_name(course, repo_name)
end.compact

testers = dockerfile_testers + starter_repo_testers

puts "Found #{testers.count} tests (#{dockerfile_testers.count} Dockerfile tests, #{starter_repo_testers.count} starter repo tests)"

if language_filter
  puts "Filtering by language:#{language_filter}"
  testers = testers.select { |tester| tester.language.slug == language_filter }
end

puts "#{testers.count} tests after filtering."

if testers.empty?
  puts "No tests found!"
  exit 1
end

testers.each { |tester| tester.test || exit(1) }
