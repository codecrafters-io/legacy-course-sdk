require "fileutils"
require "mustache"

require_relative "../lib/models"
require_relative "../lib/starter_code_uncommenter"
require_relative "../lib/unindenter"

COMMENTED_DEFINITION_FILE_CONTENTS = <<~EOF
  #author_details:
  #  name: Paul Kuruvilla
  #  profile_url: https://github.com/rohitpaulk
  #  avatar_url: https://github.com/rohitpaulk.png
  #  headline: CTO, CodeCrafters
  #reviewers_details:
  #- name: Marcos Lilljedahl
  #  profile_url: https://www.docker.com/captains/marcos-lilljedahl/
  #  avatar_url: https://github.com/marcosnils.png
  #  headline: Docker Contributor
EOF

class SolutionDefinitionsCompiler
  def initialize(course:, solutions_directory:)
    @course = course
    @solutions_directory = solutions_directory
  end

  def compile_all
    solution_directories.each do |solution_directory|
      compile_for_solution_directory(solution_directory)
    end
  end

  protected

  def compile_for_solution_directory(solution_directory)
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
