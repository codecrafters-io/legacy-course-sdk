require_relative "logger"
require_relative "test_harness"
require "tmpdir"

class SolutionTester < TestHarness
  include Logger

  attr_reader :course, :language

  def initialize(course, language)
    @course = course
    @language = language
  end

  def do_test
    log_header("Testing solutions for: #{course.slug}-#{language.slug}")

    assert dockerfiles.any?, "Expected a dockerfile to exist for #{language.slug}"

    log_info "Building image"
    build_image

    @course.stages.each do |stage|
      unless solution_exists_for_stage?(stage)
        log_info "Skipping stage #{stage.slug} because no solution exists"
        next
      end

      log_info "Running tests on solution for stage #{stage.slug}"

      time_taken = assert_time_under(30) {
        run_tests_for_stage(stage)
      }

      log_success "- Took #{time_taken} secs"
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
    Dir["../dockerfiles/*.Dockerfile"]
      .map { |dockerfile_path| File.basename(dockerfile_path) }
      .select { |dockerfile_name| dockerfile_name.start_with?(language_pack) }
  end

  def language_pack
    if language.slug.eql?("javascript")
      "nodejs"
    elsif language.slug.eql?("csharp")
      "dotnet"
    else
      language.slug
    end
  end

  def dockerfile_path
    "../dockerfiles/#{language_pack}-#{latest_version}.Dockerfile"
  end

  def starter_dir
    "../compiled_starters/#{course.slug}-starter-#{language.slug}"
  end

  def tester_path
    ".testers/#{course.slug}"
  end

  def build_image
    assert_stdout_contains(
      "docker build -t #{slug} -f #{dockerfile_path} #{starter_dir}",
      "Successfully tagged #{slug}"
    )
  end

  def run_tests_for_stage(stage)
    tmp_dir = Dir.mktmpdir

    `rm -rf #{tmp_dir}`
    `cp -R #{File.expand_path(starter_dir)} #{tmp_dir}`

    command = [
      "docker run",
      "-v #{tmp_dir}:/app",
      "-v #{File.expand_path(tester_path)}:/tester:ro",
      "-v #{File.expand_path("tests/init.sh")}:/init.sh:ro",
      "-e CODECRAFTERS_SUBMISSION_DIR=/app",
      "-e CODECRAFTERS_COURSE_PAGE_URL=http://test-app.codecrafters.io/url",
      "-e CODECRAFTERS_CURRENT_STAGE_SLUG=#{stage.slug}",
      "-e TESTER_DIR=/tester",
      "-w /app",
      "--memory=2g",
      "--cpus=0.5",
      "#{slug} /init.sh"
    ].join(" ")

    assert_stdout_contains(command, "All tests ran successfully.")
  end

  def solution_exists_for_stage?(stage)
    File.directory?("../solutions/#{@language.slug}/#{stage.slug}")
  end
end
