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

  def dir_name
    "%02d-%s" % [@number, @slug]
  end
end

class Course
  attr_reader :slug
  attr_reader :name
  attr_reader :short_name
  attr_reader :stages
  attr_reader :dir

  def initialize(slug:, name:, short_name:, stages:, dir:)
    @slug = slug
    @name = name
    @short_name = short_name
    @stages = stages
    @dir = dir
  end

  def starter_repository_definitions_file_path
    File.join(@dir, "starter-repository-definitions.yml")
  end

  def compiled_starter_repositories_dir
    File.join(@dir, "compiled_starters")
  end

  def solutions_dir
    File.join(@dir, "solutions")
  end

  def first_stage
    stages.first
  end

  def self.load_from_dir(course_dir)
    course_definition_yaml = YAML.load_file(File.join(course_dir, "course-definition.yml"))

    new(
      name: course_definition_yaml.fetch("name"),
      short_name: course_definition_yaml.fetch("short_name"),
      slug: course_definition_yaml.fetch("slug"),
      stages: course_definition_yaml.fetch("stages").each_with_index.map { |stage_yaml, stage_index|
        CourseStage.new(slug: stage_yaml.fetch("slug"), number: stage_index + 1, name: stage_yaml.fetch("name"))
      },
      dir: course_dir
    )
  end

  def source_repo_url
    "https://github.com/codecrafters-io/build-your-own-#{slug}"
  end

  def stages_after(course_stage)
    stages.drop_while { |stage| stage.slug != course_stage.slug }.drop(1)
  end

  def stage_path(language, stage, *path)
    stage_dir = [
      "%02d-%s" % [stage.number, stage.slug],
      "%d-%s" % [stage.number, stage.slug],
      stage.slug,
    ].detect { |name| File.directory?(File.join(solutions_dir, language.slug, name)) }

    return "" if stage_dir.nil?

    File.join(solutions_dir, language.slug, stage_dir, *path)
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

  def self.find_by_language_pack!(language_pack)
    return find_by_slug!("javascript") if language_pack.start_with?("nodejs")
    return find_by_slug!("csharp") if language_pack.start_with?("dotnet")
    find_by_slug!(language_pack.split("-").first)
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
      "rust" => "rs",
      "swift" => "swift"
    }.fetch(@slug)
  end

  def language_pack
    if @slug.eql?("javascript")
      "nodejs"
    elsif @slug.eql?("csharp")
      "dotnet"
    else
      @slug
    end
  end

  def syntax_highlighting_identifier
    @slug
  end
end
