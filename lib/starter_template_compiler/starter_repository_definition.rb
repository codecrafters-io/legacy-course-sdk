require "mustache"
require "yaml"

class FileMapping
  attr_reader :destination_path
  attr_reader :template_path
  attr_reader :should_skip_template_interpolation

  def initialize(destination_path, template_path, should_skip_template_interpolation)
    @destination_path = destination_path
    @template_path = template_path
    @should_skip_template_interpolation = should_skip_template_interpolation
  end

  def should_skip_template_interpolation?
    @should_skip_template_interpolation
  end
end

class StarterRepoDefinition
  attr_reader :course
  attr_reader :language
  attr_reader :file_mappings
  attr_reader :template_attrs

  def initialize(course:, language:, file_mappings:, template_attrs:)
    @course = course
    @language = language
    @file_mappings = file_mappings
    @template_attrs = template_attrs
  end

  def self.load_for_course(course)
    starter_definitions_yaml = YAML.load_file(course.starter_repository_definitions_file_path)

    starter_definitions_yaml.map do |starter_definition_yaml|
      StarterRepoDefinition.new(
        course: course,
        file_mappings: starter_definition_yaml.fetch("file_mappings").map { |fm|
          FileMapping.new(
            fm.fetch("target"),
            fm.fetch("source"),
            fm.fetch("should_skip_template_evaluation", false)
          )
        },
        language: LANGUAGES.detect { |language| language.slug == starter_definition_yaml.fetch("language") },
        template_attrs: starter_definition_yaml.fetch("template_attributes")
      )
    end
  end

  def compiled_starter_directory
    File.join(course.compiled_starter_repositories_dir, language.slug)
  end

  def files(template_dir)
    @file_mappings.map do |mapping|
      fpath = File.join(template_dir, mapping.template_path)
      template_contents = File.read(fpath)

      {
        path: mapping.destination_path,
        contents: mapping.should_skip_template_interpolation? ? template_contents : Mustache.render(template_contents, template_context),
        mode: File.stat(fpath).mode
      }
    end
  end

  private

  def template_context
    {
      language_name: @language.name,
      language_slug: @language.slug,
      "language_is_#{@language.slug}": true,
      course_name: @course.name,
      course_slug: @course.name
    }.merge(@template_attrs)
  end
end
