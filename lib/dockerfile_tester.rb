require_relative "logger"
require_relative "test_harness"
require_relative "dockerfile"

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
    return Language.find_by_slug!("javascript") if language_pack.start_with?("nodejs")
    return Language.find_by_slug!("csharp") if language_pack.start_with?("dotnet")
    Language.find_by_slug!(language_pack.split("-").first)
  end

  def do_test
    copy_starter_dir!

    log_header("Testing Dockerfile: #{slug}")

    log_info "Building #{language_pack} image without cache"
    time_taken = assert_time_under(300) { build_image }

    log_info "Took #{time_taken} secs"
    log_info ""

    log_info "Building #{language_pack} image with cache"
    time_taken = assert_time_under(5) { build_image }

    log_success "Took #{time_taken} secs"

    if dockerfile.dependency_file_paths.any?
      copy_starter_dir!

      dockerfile.dependency_file_paths.each do |dependency_file_path|
        log_info ""
        log_info "Building #{language_pack} with missing #{dependency_file_path} file"

        FileUtils.rm_rf("#{copied_starter_dir}/#{dependency_file_path}")
        time_taken = assert_time_under(300) { build_image }

        log_success "Took #{time_taken} secs"
        log_info ""
      end
    end
  end

  protected

  def build_image
    assert_stdout_contains(
      "docker build -t #{slug} -f #{dockerfile_path} #{copied_starter_dir}",
      "Successfully tagged #{slug}"
    )
  end

  def copy_starter_dir!
    @copied_starter_dir = nil
    FileUtils.cp_r(starter_dir, copied_starter_dir)
  end

  def copied_starter_dir
    @copied_starter_dir ||= Dir.mktmpdir.tap { |x| FileUtils.rmdir(x) }
  end

  def dockerfile
    @dockerfile ||= Dockerfile.parse_from_file(dockerfile_path)
  end

  def dockerfile_path
    "../dockerfiles/#{language_pack}.Dockerfile"
  end

  def slug
    "#{course.slug}-#{language_pack}"
  end

  def starter_dir
    "../compiled_starters/#{course.slug}-starter-#{language.slug}"
  end
end
