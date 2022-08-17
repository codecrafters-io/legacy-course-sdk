require_relative "../lib/repo_syncer"

github_client = Octokit::Client.new(access_token: ENV.fetch("GITHUB_TOKEN"))

syncer = RepoSyncer.new(github_client)

Dir["../compiled_starters/*"].each do |dir|
  repo_name = File.basename(dir)
  puts "Syncing #{repo_name}"
  pr_url = syncer.sync(repo_name, dir)
  if pr_url
    puts "PR: #{pr_url}"
    `open #{pr_url}` unless ENV["CI"]
    sleep 5 if ENV["CI"] # Work around PR abuse detected warnings
  else
    puts "No changes"
  end
end
