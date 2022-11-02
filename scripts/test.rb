# Usage: ruby scripts/test.rb <course_dir> <language_slug> <stage_slugs>
ENV["DOCKER_BUILDKIT"] = "0"

require "bundler/setup"
Bundler.setup(:default, :development)

require "httparty"

require_relative "../lib/solution_tester"
require_relative "../lib/tester_downloader"
require_relative "../lib/dockerfile_tester"
require_relative "../lib/starter_repo_tester"
require_relative "../lib/models"

course_dir = ARGV[0]
language_slug = ARGV[1]
stage_slugs = ARGV[2]&.split(",")

unless course_dir && language_slug
  puts "Usage: ruby scripts/test.rb <course-directory> <language-slug> [stage-slugs]"
  exit 1
end

course = Course.load_from_dir(course_dir)
compiled_starters_dir = File.join(course_dir, "compiled_starters")
dockerfiles_dir = File.join(course_dir, "dockerfiles")

language = Language.find_by_slug!(language_slug)

DOCKERFILE_NAMES_TO_SKIP = [
  "rust-1.43.Dockerfile", # Newer dependencies aren't compatible
  "rust-1.54.Dockerfile", # Newer dependencies aren't compatible
  "haskell-8.8.Dockerfile", # Newer dependencies aren't compatible
  "go-1.13.Dockerfile", # too old, not officially supported
]

STARTER_REPO_NAMES_TO_SKIP = [
  "redis-starter-elixir" # Temporarily disabled, triggers timeout
]

dockerfile_testers = Dir["#{course_dir}/dockerfiles/*.Dockerfile"].map do |dockerfile_path|
  next if DOCKERFILE_NAMES_TO_SKIP.include?(File.basename(dockerfile_path))

  DockerfileTester.new(course, compiled_starters_dir, dockerfile_path)
end.compact

starter_repo_testers = Dir["#{course_dir}/compiled_starters/*"].map do |compiled_starter_path|
  next if STARTER_REPO_NAMES_TO_SKIP.include?(File.basename(compiled_starter_path))

  StarterRepoTester.new(
    course: course,
    dockerfiles_dir: dockerfiles_dir,
    starter_dir: compiled_starter_path,
    tester_dir: TesterDownloader.new(course: course, testers_root_dir: "./testers").download_if_needed,
    language: Language.find_by_slug!(File.basename(compiled_starter_path).split("-starter-").last),
  )
end.compact

solution_tester = SolutionTester.new(
  course: course,
  dockerfiles_dir: dockerfiles_dir,
  solutions_dir: File.join(course_dir, "solutions"),
  tester_dir: TesterDownloader.new(course: course, testers_root_dir: "./testers").download_if_needed,
  language: language,
  stage_slugs: stage_slugs || course.stages.map(&:slug)
)

testers = if stage_slugs
            [solution_tester]
          else
            [
              *dockerfile_testers.select { |tester| tester.language.slug == language_slug },
              *starter_repo_testers.select { |tester| tester.language.slug == language_slug },
              solution_tester
            ]
          end

testers.each { |tester| tester.test || exit(1) }