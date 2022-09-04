require_relative "logger"
require_relative "test_harness"

require "open3"

class DockerfileTester < TestHarness
  include Logger

  attr_reader :course, :language_pack

  def initialize(course, language_pack)
    @course = course
    @language_pack = language_pack
  end

  def self.from_dockerfile(course, dockerfile_name)
    language_pack = dockerfile_name.sub(".Dockerfile", "")
    new(course, language_pack)
  end

  def language
    return "javascript" if language_pack.start_with?("nodejs")
    return "csharp" if language_pack.start_with?("dotnet")
    Language.find_by_slug!(language_pack.split("-").first)
  end

  def do_test
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
      "docker build -t #{slug} -f #{dockerfile_path} #{starter_dir}",
      "Successfully tagged #{slug}"
    )
  end

  def slug
    "#{course.slug}-#{language_pack}"
  end

  def dockerfile_path
    "../dockerfiles/#{language_pack}.Dockerfile"
  end

  def starter_dir
    "../compiled_starters/#{course.slug}-starter-#{language.slug}"
  end
end
