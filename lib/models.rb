require "yaml"

class CourseStage
  attr_reader :slug
  attr_reader :number
  attr_reader :name

  def initialize(slug:, number:, name:)
    @slug = slug
    @number = number
    @name = name
  end
end

class Course
  attr_reader :slug
  attr_reader :name
  attr_reader :short_name
  attr_reader :stages

  def initialize(slug:, name:, short_name:, stages:)
    @slug = slug
    @name = name
    @short_name = short_name
    @stages = stages
  end

  def first_stage
    stages.first
  end

  def self.load_from_file(file_path)
    course_definition_yaml = YAML.load_file(file_path)

    new(
      name: course_definition_yaml.fetch("name"),
      short_name: course_definition_yaml.fetch("short_name"),
      slug: course_definition_yaml.fetch("slug"),
      stages: course_definition_yaml.fetch("stages").each_with_index.map { |stage_yaml, stage_index|
        CourseStage.new(slug: stage_yaml.fetch("slug"), number: stage_index + 1, name: stage_yaml.fetch("name"))
      }
    )
  end
end

class Language
  attr_reader :slug
  attr_reader :name
  attr_reader :repo_suffix

  def initialize(slug:, name:, repo_suffix:)
    @slug = slug
    @name = name
    @repo_suffix = repo_suffix
  end

  def self.find_by_slug!(slug)
    require_relative "languages"
    LANGUAGES.detect(-> { raise "Language with slug #{slug} not found" }) { |language| language.slug.eql?(slug) }
  end

  def code_file_extension
    {
      "c" => "c",
      "clojure" => "clj",
      "crystal" => "cr",
      "csharp" => "cs",
      "elixir" => "ex",
      "go" => "go",
      "haskell" => "hs",
      "java" => "java",
      "javascript" => "js",
      "kotlin" => "kt",
      "nim" => "nim",
      "php" => "php",
      "python" => "py",
      "ruby" => "rb",
      "rust" => "rs"
    }.fetch(@slug)
  end

  def syntax_highlighting_identifier
    @slug
  end
end
