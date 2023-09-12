require_relative "logger"
require_relative "test_harness"
require "tmpdir"

class SolutionTester < TestHarness
  include CustomLogger

  attr_reader :course, :dockerfiles_dir, :solutions_dir, :tester_dir, :language

  def initialize(course:, dockerfiles_dir:, solutions_dir:, tester_dir:, language:, stage_slugs:)
    @course = course
    @dockerfiles_dir = dockerfiles_dir
    @solutions_dir = solutions_dir
    @tester_dir = tester_dir
    @language = language
    @stage_slugs = stage_slugs
  end

  def do_test
    log_header("Testing solutions for: #{course.slug}-#{language.slug}")

    assert dockerfiles.any?, "Expected a dockerfile to exist for #{language.slug}"

    log_info "Building image"

    @course.stages.each do |stage|
      unless solution_exists_for_stage?(stage)
        log_info "Skipping stage #{stage.slug} because no solution exists"
        next
      end

      unless @stage_slugs.include?(stage.slug)
        log_info "Skipping stage #{stage.slug} because we're only running tests for #{@stage_slugs}"
        next
      end

      build_image(stage)
      log_info "Running tests on solution for stage #{stage.slug}"

      time_taken = assert_time_under(60) {
        run_tests_for_stage(stage)
      }

      log_success "Took #{time_taken} secs"
      log_success("")
    end
  end

  def latest_version
    dockerfiles
      .map { |dockerfile_name| dockerfile_name.sub(".Dockerfile", "") }
      .map { |dockerfile_name| dockerfile_name.split("-").last }
      .sort_by { |version| Gem::Version.new(version) }
      .last
  end

  def slug
    "#{course.slug}-#{language_pack}-#{latest_version}"
  end

  def dockerfiles
    Dir["#{dockerfiles_dir}/*.Dockerfile"]
      .map { |dockerfile_path| File.basename(dockerfile_path) }
      .select { |dockerfile_name| dockerfile_name.start_with?("#{language_pack}-") }
  end

  def language_pack
    language.language_pack
  end

  def dockerfile_path
    "#{dockerfiles_dir}/#{language_pack}-#{latest_version}.Dockerfile"
  end

  def solution_code_dir_for_stage(stage)
    "#{solutions_dir}/#{@language.slug}/#{stage.solution_dir}/code"
  end

  def build_image(stage)
    assert_stderr_contains(
      "docker build -t #{slug} -f #{dockerfile_path} #{solution_code_dir_for_stage(stage)}",
      "naming to docker.io/library/#{slug}"
    )
  end

  def run_tests_for_stage(stage)
    FileUtils.mkdir_p("./tmp")
    tmp_dir = Dir.mktmpdir("solution_tester", "./tmp")

    `rm -rf #{tmp_dir}`
    `cp -R #{File.expand_path(solution_code_dir_for_stage(stage))} #{tmp_dir}`

    command = [
      "docker run",
      "--rm",
      "--cap-add SYS_ADMIN",
      "-v '#{File.expand_path(tmp_dir, ENV["HOST_COURSE_SDK_PATH"])}:/app'",
      "-v '#{File.expand_path(tester_dir, ENV["HOST_COURSE_SDK_PATH"])}:/tester:ro'",
      "-v '#{File.expand_path("tests/init.sh", ENV["HOST_COURSE_SDK_PATH"])}:/init.sh:ro'",
      "-e CODECRAFTERS_SUBMISSION_DIR=/app",
      "-e CODECRAFTERS_COURSE_PAGE_URL=http://test-app.codecrafters.io/url",
      "-e CODECRAFTERS_CURRENT_STAGE_SLUG=#{stage.slug}",
      "-e TESTER_DIR=/tester",
      "-w /app",
      "--memory=2g",
      "--cpus=0.5",
      "#{slug} /init.sh"
    ].join(" ")

    assert_stdout_contains(command, "Test passed.")
  end

  def solution_exists_for_stage?(stage)
    File.directory?("#{solutions_dir}/#{@language.slug}/#{stage.solution_dir}")
  end
end
