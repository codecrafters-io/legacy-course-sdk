require "fileutils"
require "pmap"

require_relative "../models"
require_relative "starter_repository_definition"
require_relative "../languages"

class StarterTemplateCompiler
  POSTPROCESSORS = {
    "md" => proc { |filepath| `/node-app/node_modules/.bin/prettier --prose-wrap="always" --write #{filepath}` },
    "js" => proc { |filepath| `/node-app/node_modules/.bin/prettier --write #{filepath}` }
  }

  def initialize(templates_directory:, output_directory:, definitions:)
    @definitions = definitions
    @templates_directory = templates_directory
    @output_directory = output_directory
  end

  def compile_all
    @definitions.pmap do |definition|
      puts "compiling starter repositories for #{definition.course.slug}-#{definition.language.slug}"
      compile_definition(definition)
    end
  end

  def compile_for_language(language_slug)
    @definitions.each do |definition|
      next unless definition.language.slug.eql?(language_slug)

      puts "compiling #{definition.course.slug}-#{definition.language.slug}"
      compile_definition(definition)
    end
  end

  private

  def compile_definition(definition)
    directory = File.join(@output_directory, definition.repo_name)
    FileUtils.rmtree(directory)

    definition.files(@templates_directory).each do |file|
      path = File.join(directory, file[:path])
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, file[:contents])
      FileUtils.chmod(0o755, path) if file[:is_executable]
      postprocess!(path)
    end
  end

  def postprocess!(filepath)
    POSTPROCESSORS["md"].call(filepath) if filepath.end_with?(".md")
    POSTPROCESSORS["js"].call(filepath) if filepath.end_with?(".js")
  end
end
