require "fileutils"
require "mustache"

require_relative "../lib/models"
require_relative "../lib/starter_code_uncommenter"
require_relative "../lib/unindenter"

COMMENTED_DEFINITION_FILE_CONTENTS = <<~EOF
  author_details:
    name: Paul Kuruvilla
    profile_url: https://github.com/rohitpaulk
    avatar_url: https://github.com/rohitpaulk.png
    headline: CTO, CodeCrafters
  #reviewers_details:
  #- name: Marcos Lilljedahl
  #  profile_url: https://www.docker.com/captains/marcos-lilljedahl/
  #  avatar_url: https://github.com/marcosnils.png
  #  headline: Docker Contributor
  #pull_request_url: "https://github.com/codecrafters-io/build-your-own-<course>/pull/<number>"
EOF

class SolutionDefinitionsCompiler
  def initialize(course:)
    @course = course
  end

  def compile_all
    solution_directories.each do |solution_directory|
      compile_for_solution_directory(solution_directory)
    end
  end

  def compile_for_language(language)
    solution_directories
      .select { |solution_dir| File.dirname(File.dirname(solution_dir)).eql?(language.slug) }
      .map { |solution_dir| compile_for_solution_directory(solution_dir) }
  end

  protected

  def compile_for_solution_directory(solution_directory)
    language = Language.find_by_slug!(File.basename(File.dirname(solution_directory)))
    stage = @course.stages.detect { |stage| File.basename(solution_directory).match?("(0*%d-)?%s" % [stage.number, stage.slug]) }
    definition_file_path = File.join(solution_directory, "definition.yml")

    unless File.exist?(definition_file_path)
      puts "- Adding commented solution definition for #{@course.slug} (#{language.slug}, #{stage.slug})..."
      File.write(definition_file_path, COMMENTED_DEFINITION_FILE_CONTENTS)
    end
  end

  def solution_directories
    Dir.glob(File.join(@course.solutions_dir, "*", "*", "code")).map { |path| File.dirname(path) }
  end
end
