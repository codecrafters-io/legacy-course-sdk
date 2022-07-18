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
    definition_file_path = File.join(File.dirname(solution_directory), "definition.yml")

    File.delete(definition_file_path) if File.exist?(definition_file_path)

    File.write(definition_file_path, YAML.dump(
      author_details: {
        name: 'Paul Kuruvilla',
        profileUrl: 'https://github.com/rohitpaulk',
        avatarUrl: 'https://github.com/rohitpaulk.png',
        headline: 'CTO, CodeCrafters',
      },
      reviewers_details: [
        {
          name: 'Marcos Lilljedahl',
          profileUrl: 'https://www.docker.com/captains/marcos-lilljedahl/',
          avatarUrl: 'https://github.com/marcosnils.png',
          headline: 'Docker Contributor',
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
    Dir.glob(File.join(@solutions_directory, "*", "*"))
  end
end
