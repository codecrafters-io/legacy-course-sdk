# Usage: ruby scripts/test_downloader.rb courses/redis
require "bundler/setup"
Bundler.setup(:default, :development)

require "httparty"

require_relative "../lib/solution_tester"
require_relative "../lib/tester_downloader"
require_relative "../lib/dockerfile_tester"
require_relative "../lib/starter_repo_tester"
require_relative "../lib/models"

course_dir = ARGV[0]

unless course_dir
  puts "Usage: ruby scripts/test_downloader.rb <course-directory>"
  exit 1
end

course = Course.load_from_dir(course_dir)
puts "downloading"
TesterDownloader.new(course: course, testers_root_dir: "./testers").download_if_needed
puts "downloaded"