require_relative "../lib/models"

# Generates pull requests for expert reviewers based on existing content
class PullRequestGenerator
  def initialize(course:, solutions_directory:)
    @course = course
    @solutions_directory = solutions_directory
  end

  def generate_all
    solution_directories.each do |solution_directory|
      generate_for_solution_directory(solution_directory)
      raise "hey"
    end
  end

  protected

  def generate_for_solution_directory(solution_directory)
    solution_definition_contents = File.read(File.join(solution_directory, "definition.yml"))

    if YAML.load(solution_definition_contents)["pull_request_url"]
      puts "Skipped #{solution_directory} because it already has a pull request"
    end

    language = Language.find_by_slug!(File.basename(File.dirname(solution_directory)))
    stage = @course.stages.detect { |stage| stage.slug.eql?(File.basename(solution_directory)) }

    github_repo_name = "codecrafters-io/#{File.basename(File.dirname(Dir.pwd))}"

    github_client = Octokit::Client.new(access_token: ENV["GITHUB_TOKEN"])
    gh_repo = github_client.repository(github_repo_name)
    current_commit_sha = gh_client.commit(gh_repo_name, "main").commit.sha
    current_tree_sha = gh_client.commit(gh_repo_name, "main").commit.tree.sha

    base_branch_tree = gh_client.create_tree(
      gh_repo_name,
      [
        {
          path: "solutions/#{language.slug}/#{stage.slug}",
          sha: null
        }
      ],
      base_tree_sha: current_tree_sha
    )

    base_commit = gh_client.create_commit(
      gh_repo,
      "remove old solution for #{language.slug} - ##{stage.number} (#{stage.name})",
      base_branch_tree.sha,
      current_commit_sha
    )

    head_commit = gh_client.create_commit(
      gh_repo,
      "add solution for #{language.slug} - ##{stage.number} (#{stage.name})",
      current_tree_sha,
      base_commit.sha
    )

    base_branch_name = "base-for-#{language.slug}-stage-#{stage.number}"
    head_branch_name = "add-#{language.slug}-stage-#{stage.number}"

    github_client.create_ref(github_repo_name, "heads/#{base_branch_name}", base_commit.sha)
    github_client.create_ref(github_repo_name, "heads/#{head_branch_name}", head_commit.sha)

    pull_request = github_client.create_pull_request(
      github_repo_name,
      base_branch_name,
      head_branch_name,
      "Add solution for #{language.slug} - ##{stage.number} (#{stage.name})",
      <<~EOF
        The solution for this stage was created before we setup the reviews feature. You'll notice that this PR doesn't
        target the `main` branch, this is because the `main` branch already contains the "unreviewed" solution. 

        This PR doesn't have to be merged, it's created for the sole purpose of being reviewed using GitHub's Pull 
        Request UI. Any changes recommended here will be later merged into the `main` branch.
      EOF
    )

    puts "Created pull request: #{pull_request.html_url}"

    solution_definition_contents.gsub!(/#pull_request_url: .*/, "pull_request_url: #{pull_request.html_url}")
    File.write(File.join(solution_directory, "definition.yml"), solution_definition_contents)
  end

  def solution_directories
    Dir.glob(File.join(@solutions_directory, "*", "*", "code")).map { |path| File.dirname(path) }
  end
end

pull_request_generator = PullRequestGenerator.new(
  course: Course.load_from_file("../course-definition.yml"),
  solutions_directory: "../solutions"
)

pull_request_generator.generate_all
