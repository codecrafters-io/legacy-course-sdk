# Usage: ruby scripts/import_solution_code.rb <language_slug> <stage_number> <solution_dir>
# Example: ruby scripts/import_solution_code.rb python 2 /tmp/codecrafters-redis-python
require_relative "../lib/models"

language_slug = ARGV[0]
stage_number = Integer(ARGV[1])
reference_solution_directory = ARGV[2]

course = Course.load_from_file("../course-definition.yml")
language = Language.find_by_slug!(language_slug)
course_stage = course.stages[stage_number - 1]

solution_code_directory = File.join("../solutions", language.slug, course_stage.slug, "code")
relative_file_paths = `git -C #{reference_solution_directory} ls-tree -r master --name-only`
relative_file_paths = relative_file_paths.split("\n").map(&:strip)

relative_file_paths.each do |relative_file_path|
  reference_file_path = File.join(reference_solution_directory, relative_file_path)
  solution_file_path = File.join(solution_code_directory, relative_file_path)
  FileUtils.mkdir_p(File.dirname(solution_file_path))
  `cp #{reference_file_path} #{solution_file_path}`
  puts "- imported #{relative_file_path}"
end
