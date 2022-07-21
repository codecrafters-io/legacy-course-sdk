# Generates pull requests for expert reviewers based on existing content
class PullRequestGenerator
  def initialize(course:, solutions_directory:)
    @course = course
    @solutions_directory = solutions_directory
  end

  def generate_all
    solution_directories.each do |solution_directory|
      generate_for_solution_directory(solution_directory)
    end
  end

  protected

  def generate_for_solution_directory(solution_directory)
    solution_definition_contents = File.read(File.join(solution_directory, "definition.yml"))
    solution_definition = YAML.load(solution_definition_contents)

    if solution_definition_yaml["pull_request_url"]
      puts "Skipped #{solution_directory} because it already has a pull request"
    end

    pull_request_url = "abcd"
    solution_definition_contents.gsub!(/#pull_request_url: .*/, "pull_request_url: #{pull_request_url}")
    return

    language = Language.find_by_slug!(File.basename(File.dirname(solution_directory)))
    stage = @course.stages.detect { |stage| stage.slug.eql?(File.basename(solution_directory)) }
    definition_file_path = File.join(solution_directory, "definition.yml")

    unless File.exist?(definition_file_path)
      puts "- Adding commented solution definition for #{@course.slug} (#{language.slug}, #{stage.slug})..."
      File.write(definition_file_path, COMMENTED_DEFINITION_FILE_CONTENTS)
    end
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
