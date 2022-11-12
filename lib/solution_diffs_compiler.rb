require "fileutils"
require "diffy"

class ChangedFile
  attr_reader :path
  attr_reader :old_contents
  attr_reader :new_contents

  def initialize(path:, old_contents:, new_contents:)
    @path = path
    @old_contents = old_contents
    @new_contents = new_contents
  end

  def diff
    Diffy::Diff.new(old_contents, new_contents, include_diff_info: true, context: 25).to_s(:text).lines.map(&:rstrip)[2..].join("\n") + "\n"
  end
end

class SolutionDiffsCompiler
  def initialize(course:)
    @course = course
  end

  def compile_all
    languages.each do |language|
      compile_for_language(language)
    end
  end

  def stage_dir(language, stage, *path)
    stage_dir = [
      "%02d-%s" % [stage.number, stage.slug],
      "%d-%s" % [stage.number, stage.slug],
      stage.slug,
    ].detect { |name| File.directory?(File.join(@course.solutions_dir, language.slug, name)) }

    return "" if stage_dir.nil?

    File.join(@course.solutions_dir, language.slug, stage_dir, *path)
  end

  def compile_for_language(language)
    puts "compiling solution diffs for #{@course.slug}-#{language.slug}"

    [[nil, @course.first_stage], *@course.stages.each_cons(2)].each do |previous_stage, next_stage|
      previous_stage_code_directory = if previous_stage
        stage_dir(language, previous_stage, "code")
      else
        starter_directory_for(language)
      end

      next_stage_code_directory = stage_dir(language, next_stage, "code")

      next unless File.directory?(previous_stage_code_directory) && File.directory?(next_stage_code_directory)

      next_stage_diff_directory = stage_dir(language, next_stage, "diff")
      FileUtils.rm_rf(next_stage_diff_directory) if File.exist?(next_stage_diff_directory)
      FileUtils.mkdir_p(next_stage_diff_directory)

      changed_files = compute_changed_files(previous_stage_code_directory, next_stage_code_directory)

      changed_files.each do |changed_file|
        diff_file_path = "#{File.join(next_stage_diff_directory, changed_file.path)}.diff"
        FileUtils.mkdir_p(File.dirname(diff_file_path))
        File.write(diff_file_path, changed_file.diff)
      end
    end
  end

  protected

  def compute_changed_files(source_directory, target_directory)
    source_directory_files = Dir.glob("#{source_directory}/**/*").select { |file_path| File.file?(file_path) }
    target_directory_files = Dir.glob("#{target_directory}/**/*").select { |file_path| File.file?(file_path) }

    changed_files = []

    target_directory_files.each do |target_directory_file|
      relative_path = Pathname.new(target_directory_file).relative_path_from(Pathname.new(target_directory)).to_s

      source_directory_file = source_directory_files.find { |source_directory_file|
        source_relative_path = Pathname.new(source_directory_file).relative_path_from(Pathname.new(source_directory)).to_s
        source_relative_path == relative_path
      }

      old_contents = source_directory_file ? File.read(source_directory_file) : nil
      new_contents = File.read(target_directory_file)

      unless old_contents.eql?(new_contents)
        changed_files << ChangedFile.new(
          path: relative_path,
          old_contents: old_contents, # can be nil
          new_contents: new_contents
        )
      end
    end

    source_directory_files.each do |source_directory_file|
      relative_path = Pathname.new(source_directory_file).relative_path_from(Pathname.new(source_directory)).to_s

      target_directory_file = target_directory_files.find { |target_directory_file|
        target_relative_path = Pathname.new(target_directory_file).relative_path_from(Pathname.new(target_directory)).to_s
        target_relative_path == relative_path
      }

      # Only add removed files here, the rest are covered above
      if target_directory_file.nil?
        changed_files << ChangedFile.new(
          path: relative_path,
          old_contents: File.read(source_directory_file),
          new_contents: nil
        )
      end
    end

    changed_files
  end

  def languages
    Dir.glob("#{@course.solutions_dir}/*").map { |language_directory| Language.find_by_slug!(File.basename(language_directory)) }
  end

  def starter_directory_for(language)
    File.join(@course.compiled_starter_repositories_dir, "#{@course.slug}-starter-#{language.slug}")
  end
end
