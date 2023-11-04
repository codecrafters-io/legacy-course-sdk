require_relative "logger"
require_relative "starter_code_uncommenter"
require_relative "line_with_comment_remover"

class StarterRepoTester < TestHarness
  include CustomLogger

  attr_reader :course, :dockerfiles_dir, :starter_dir, :tester_dir, :language

  def initialize(course:, dockerfiles_dir:, starter_dir:, tester_dir:, language:)
    @course = course
    @dockerfiles_dir = dockerfiles_dir
    @starter_dir = starter_dir
    @tester_dir = tester_dir
    @language = language
  end

  def copied_starter_dir
    @copied_starter_dir ||= Dir.mktmpdir.tap { |x| FileUtils.rmdir(x) }
  end

  def do_test
    FileUtils.cp_r(starter_dir, copied_starter_dir)

    log_header("Testing starter: #{course.slug}-starter-#{language.slug}")

    assert dockerfiles.any?, "Expected a dockerfile to exist for #{slug}"

    expected_yaml_language_pack = "#{language_pack}-#{latest_version}"
    actual_yaml_language_pack = YAML.load_file("#{copied_starter_dir}/codecrafters.yml").fetch("language_pack")
    assert expected_yaml_language_pack.eql?(actual_yaml_language_pack), "Expected .codecrafters.yml to have language_pack: #{expected_yaml_language_pack}, but found #{actual_yaml_language_pack}"

    log_info "Building image"
    build_image

    log_info "Executing starter repo script"
    assert_time_under(20) {
      assert_script_output("Logs from your program will appear here", expected_exit_code = 1)
    }

    log_success "Script output verified"

    log_info "Checking if there are no uncommitted changes to compiled templates"

    diff_command = "git -C #{starter_dir} diff --exit-code"
    diff = `#{diff_command}`
    exit_status = $?.exitstatus

    if exit_status != 0
      log_info "There are uncommitted changes to compiled templates in #{starter_dir}:"
      log_info diff
      log_error "Please commit these changes and try again."

      raise TestFailedError
    else
      log_success "No uncommitted changes to compiled templates found."
    end

    log_info "Checking if there are no untracked changes to compiled templates"

    list_untracked_files_command = "git -C #{starter_dir} ls-files --others --exclude-standard"
    untracked_files = `#{list_untracked_files_command}`

    if untracked_files.empty?
      log_success "No untracked changes to compiled templates found."
    else
      log_info "There are untracked changes to compiled templates in #{starter_dir}:"
      log_info untracked_files
      log_error "Please track these changes and try again."

      raise TestFailedError
    end

    log_info "Uncommenting starter code..."

    diffs = StarterCodeUncommenter.new(copied_starter_dir, language).uncomment
    diffs.each do |diff|
      if diff.to_s.empty?
        log_error("Expected uncommenting code to return a diff")
        log_error("Are you sure there's a contiguous block of comments after the 'Uncomment this' marker?")
        return
      end

      puts ""
      puts diff.to_s(:color)
      puts ""
    end

    diffs = LineWithCommentRemover.new(copied_starter_dir, language).process!
    diffs.each do |diff|
      if diff.to_s.empty?
        log_error("Expected removing logger line to return a diff")
        log_error("Are you sure there's a line that matches #{LineWithCommentRemover::LINE_MARKER_PATTERN.inspect} in any of these files: #{LineWithCommentRemover.new(copied_starter_dir, language).code_files}?")

        return
      end
    end

    log_info "Executing starter repo script with first stage uncommented"
    time_taken = assert_time_under(20) {
      assert_script_output("Test passed.")
    }

    log_success "Took #{time_taken} secs"
  end

  def dockerfile_path
    "#{dockerfiles_dir}/#{language_pack}-#{latest_version}.Dockerfile"
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

  def build_image
    assert_stderr_contains(
      "docker build -t #{slug} -f #{dockerfile_path} #{copied_starter_dir}",
      "naming to docker.io/library/#{slug}"
    )
  end

  def assert_script_output(expected_output, expected_exit_code = 0)
    FileUtils.mkdir_p("./tmp")
    tmp_dir = Dir.mktmpdir("starter_repo_tester", "./tmp")

    `rm -rf #{tmp_dir}`
    `cp -R #{File.expand_path(copied_starter_dir)} #{tmp_dir}`

    command = [
      "docker run",
      "--rm",
      "-v '#{File.expand_path(tmp_dir, ENV["HOST_COURSE_SDK_PATH"])}:/app'",
      "-v '#{File.expand_path(tester_dir, ENV["HOST_COURSE_SDK_PATH"])}:/tester:ro'",
      "-v '#{File.expand_path("tests/init.sh", ENV["HOST_COURSE_SDK_PATH"])}:/init.sh:ro'",
      "-e CODECRAFTERS_SUBMISSION_DIR=/app",
      "-e CODECRAFTERS_TEST_CASES_JSON='[#{course.first_stage.tester_test_case_json}]'",
      "-e CODECRAFTERS_CURRENT_STAGE_SLUG=#{course.first_stage.slug}", # TODO: Remove this
      "-e TESTER_DIR=/tester",
      "-w /app",
      "--memory=2g",
      "--cpus=0.5",
      "#{slug} /init.sh"
    ].join(" ")

    assert_stdout_contains(
      command,
      expected_output,
      expected_exit_code = expected_exit_code
    )
  end
end
