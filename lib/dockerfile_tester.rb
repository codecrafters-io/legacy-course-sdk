require_relative "logger"
require_relative "test_harness"

require "open3"

class DockerfileTester < TestHarness
  include CustomLogger

  attr_reader :course, :compiled_starters_dir, :dockerfile_path

  def initialize(course, compiled_starters_dir, dockerfile_path)
    @course = course
    @compiled_starters_dir = compiled_starters_dir
    @dockerfile_path = dockerfile_path
  end

  def copied_starter_dir
    @copied_starter_dir ||= Dir.mktmpdir.tap { |x| FileUtils.rmdir(x) }
  end

  def language
    Language.find_by_language_pack!(language_pack)
  end

  def language_pack
    File.basename(dockerfile_path).sub(".Dockerfile", "")
  end

  def do_test
    FileUtils.cp_r(starter_dir, copied_starter_dir)

    log_header("Testing Dockerfile: #{slug}")

    log_info "Building #{language_pack} image without cache"
    time_taken = assert_time_under(300) { build_image }

    log_info "Took #{time_taken} secs"
    log_info ""

    log_info "Building #{language_pack} image with cache"
    time_taken = assert_time_under(5) { build_image }

    log_success "Took #{time_taken} secs"
  end

  def build_image
    assert_stdout_contains(
      "docker build -t #{slug} -f #{dockerfile_path} #{copied_starter_dir}",
      "Successfully tagged #{slug}"
    )
  end

  def slug
    "#{course.slug}-#{language_pack}"
  end

  def starter_dir
    "#{compiled_starters_dir}/#{course.slug}-starter-#{language.slug}"
  end
end
