require "fileutils"
require "mustache"

require_relative "../lib/models"
require_relative "../lib/starter_code_uncommenter"
require_relative "../lib/unindenter"

class FirstStageExplanationsCompiler
  def initialize(course:)
    @course = course
  end

  def compile_all
    starter_repository_directories.each do |starter_repository_directory|
      compile_for_starter_repository_directory(starter_repository_directory)
    end
  end

  def compile_for_language(language)
    starter_repository_directories
      .select { |starter_repository_directory| File.basename(starter_repository_directory).split("-").last.eql?(language.slug) }
      .map { |starter_repository_directory| compile_for_starter_repository_directory(starter_repository_directory) }
  end

  def compile_for_starter_repository_directory(starter_repository_directory)
    language = Language.find_by_slug!(File.basename(starter_repository_directory).split("-").last)
    explanation_file_path = @course.stage_path(language, @course.first_stage, "explanation.md")

    File.delete(explanation_file_path) if File.exist?(explanation_file_path)
    FileUtils.mkdir_p(File.dirname(explanation_file_path))

    blocks = StarterCodeUncommenter.new(starter_repository_directory, language).uncommented_blocks_with_markers
    template_contents = File.read("lib/first_stage_explanation_template.md")

    blocks = blocks.map do |block|
      {
        file_path: block[:file_path],
        code: Unindenter.unindent(block[:code])
      }
    end

    File.write(explanation_file_path, Mustache.render(template_contents, {
      course_short_name: @course.short_name,
      uncommented_code_blocks: blocks,
      entry_point_file: blocks.first[:file_path],
      language_syntax_highlighting_identifier: language.slug
    }))
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

  def starter_repository_directories
    Dir.glob(File.join(@course.compiled_starter_repositories_dir, "#{@course.slug}-starter-*"))
  end
end
