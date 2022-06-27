# Usage: ruby scripts/import_solution_code.rb <language_slug> <stage_number> <solution_dir>
require_relative "../lib/models"

language_slug = ARGV[0]
stage_number = Integer(ARGV[1])
reference_solution_directory = ARGV[2]

course = Course.load_from_file("../course-definition.yml")
language = Language.find_by_slug!(language_slug)
course_stage = course.stages[stage_number - 1]

solution_code_directory = File.join("../solutions", language.slug, course_stage.slug, code)
`rm -rf #{solution_code_directory}`
`cp -R #{reference_solution_directory} #{solution_code_directory}`
