require "fileutils"

require_relative "../lib/models"
require_relative "../lib/starter_code_uncommenter"
require_relative "../lib/line_with_comment_remover"

class FirstStageSolutionsCompiler
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
    code_directory = File.join(@course.solutions_dir, language.slug, @course.first_stage.solution_dir, "code")

    FileUtils.rm_rf(code_directory) if File.exist?(code_directory)
    FileUtils.mkdir_p(code_directory)
    FileUtils.cp_r("#{starter_repository_directory}/.", code_directory)

    diffs = LineWithCommentRemover.new(code_directory, language).process!
    ensure_diffs_exist!(diffs)

    diffs = StarterCodeUncommenter.new(code_directory, language).uncomment
    ensure_diffs_exist!(diffs)
  end

  protected

  def ensure_diffs_exist!(diffs)
    diffs.each do |diff|
      if diff.to_s.empty?
        log_error("Expected uncommenting code to return a diff")
        log_error("Are you sure there's a contiguous block of comments after the 'Uncomment this' marker?")

        exit(1)
      end

      # puts ""
      # puts diff.to_s(:color)
      # puts ""
    end
  end

  def starter_repository_directories
    Dir.glob(File.join(@course.compiled_starter_repositories_dir, "#{@course.slug}-starter-*"))
  end
end
