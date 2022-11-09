require_relative "../lib/repo_syncer"

course_dir = ARGV[0]

unless course_dir
  puts "Usage: ruby scripts/sync_starter_repositories.rb <course-directory>"
  exit 1
end

course = Course.load_from_dir(course_dir)
github_client = Octokit::Client.new(access_token: ENV.fetch("GITHUB_TOKEN"))

syncer = RepoSyncer.new(github_client)

Dir["#{course_dir}/compiled_starters/*"].each do |dir|
  repo_name = File.basename(dir)
  puts `ls -la #{dir}`
  puts "Syncing #{repo_name}"
  pr_url = syncer.sync(course, repo_name, dir)
  if pr_url
    puts "PR: #{pr_url}"
    sleep 5 if ENV["CI"] # Work around PR abuse detected warnings
  else
    puts "No changes"
  end
end
