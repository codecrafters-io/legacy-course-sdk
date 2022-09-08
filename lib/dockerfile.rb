class Dockerfile < Struct.new(:dependency_file_paths, keyword_init: true)
  def self.parse_from_file(file_path)
    dockerfile_contents = File.read(file_path)
    dependency_line_matches = dockerfile_contents.match(/CODECRAFTERS_DEPENDENCY_FILE_PATHS="([^"]*)"/)

    new(dependency_file_paths: dependency_line_matches ? dependency_line_matches[1].split(",") : [])
  end
end
