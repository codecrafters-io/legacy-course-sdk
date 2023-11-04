require "fileutils"
require "pmap"

require_relative "../models"
require_relative "starter_repository_definition"
require_relative "../languages"

class StarterTemplateCompiler
  POSTPROCESSORS = {
    "md" => proc { |filepath| `prettier --prose-wrap="always" --write --ignore-path ./.prettierignore #{filepath}` },
    "js" => proc { |filepath| `prettier --write --ignore-path ./.prettierignore #{filepath}` }
  }

  def initialize(course:)
    @course = course
  end

  def compile_all
    definitions.pmap do |definition|
      puts "compiling starter repositories for #{definition.course.slug}-#{definition.language.slug}"
      compile_definition(definition)
    end
  end

  def compile_for_language(language)
    definitions.each do |definition|
      next unless definition.language.slug.eql?(language.slug)

      puts "compiling #{definition.course.slug}-#{definition.language.slug}"
      compile_definition(definition)
    end
  end

  private

  def compile_definition(definition)
    directory = definition.compiled_starter_directory
    FileUtils.rmtree(directory)

    definition.files(@course.dir).each do |file|
      path = File.join(directory, file[:path])
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, file[:contents])
      FileUtils.chmod(file[:mode], path)
      postprocess!(path)
    end

    definition.template_attrs.each do |key, value|
      if key.end_with?("_file")
        unless definition.file_mappings.map(&:destination_path).include?(value)
          raise "Template attribute #{key} references #{value}, which doesn't exist in the starter repository"
        end
      end
    end
  end

  def definitions
    @definitions ||= StarterRepoDefinition.load_for_course(@course)
  end

  def postprocess!(filepath)
    POSTPROCESSORS["md"].call(filepath) if filepath.end_with?(".md")
    POSTPROCESSORS["js"].call(filepath) if filepath.end_with?(".js")
  end
end
