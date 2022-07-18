require "fileutils"
require "mustache"

require_relative "../lib/models"
require_relative "../lib/starter_code_uncommenter"
require_relative "../lib/unindenter"

class FirstStageSolutionDefinitionsCompiler
  def initialize(course:, solutions_directory:)
    @course = course
    @solutions_directory = solutions_directory
  end

  def compile_all
    solution_directories.each do |solution_directory|
      compile_for_solution_directory(solution_directory)
    end
  end

  def compile_for_solution_directory(solution_directory)
    language = Language.find_by_slug!(File.basename(File.dirname(solution_directory)))
    stage = @course.stages.detect { |stage| stage.slug.eql?(File.basename(solution_directory)) }
    definition_file_path = File.join(solution_directory, "definition.yml")

    puts "- Compiling solution definitions for #{@course.slug} (#{language.slug}, #{stage.slug})..."

    File.delete(definition_file_path) if File.exist?(definition_file_path)

    File.write(definition_file_path, YAML.dump(
      "author_details" => {
        "name" => 'Paul Kuruvilla',
        "profile_url" => 'https://github.com/rohitpaulk',
        "avatar_url" => 'https://github.com/rohitpaulk.png',
        "headline" => 'CTO, CodeCrafters',
      },
      "reviewers_details" => [
        {
          "name" => 'Marcos Lilljedahl',
          "profile_url" => 'https://www.docker.com/captains/marcos-lilljedahl/',
          "avatar_url" => 'https://github.com/marcosnils.png',
          "headline" => 'Docker Contributor',
        }
      ]
    ))
  end

  protected

  def ensure_blocks_exist!(blocks)
    blocks.each do |block|
      if block.strip.empty?
        log_error("Expected uncommenting code to return a block with a marker")
        log_error("Are you sure there's a contiguous block of comments after the 'Uncomment this' marker?")

        exit(1)
      end

      # puts ""
      # puts blocks.inspect
      # puts ""
    end
  end

  # For now, we're compiling for _all_ stages - in the future only do for first, manually manage others.
  def solution_directories
    Dir.glob(File.join(@solutions_directory, "*", "*", "code")).map { |path| File.dirname(path) }
  end
end
