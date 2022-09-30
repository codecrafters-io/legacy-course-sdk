# Usage: ruby scripts/compile.rb <course_dir> <language_slug>
require_relative "../lib/starter_template_compiler/compiler"
require_relative "../lib/solution_diffs_compiler"
require_relative "../lib/solution_definitions_compiler"
require_relative "../lib/first_stage_solutions_compiler"
require_relative "../lib/first_stage_explanations_compiler"
require_relative "../lib/models"

course_dir = ARGV[0]
language_filter = ARGV[1]

unless course_dir
  puts "Usage: ruby scripts/compile.rb <course-directory> [language-filter]"
  exit 1
end

course = Course.load_from_file(File.join(course_dir, "course-definition.yml"))

compiled_starters_dir = File.join(course_dir, "compiled_starters")
solutions_dir = File.join(course_dir, "solutions")
starter_repository_definitions_file_path = File.join(course_dir, "starter-repository-definitions.yml")

starter_template_compiler = StarterTemplateCompiler.new(
  output_directory: compiled_starters_dir,
  templates_directory: course_dir,
  definitions: StarterRepoDefinition.load_from_file(course, starter_repository_definitions_file_path)
)

solution_diffs_compiler = SolutionDiffsCompiler.new(
  course: course,
  solutions_directory: solutions_dir,
  starters_directory: compiled_starters_dir,
)

solution_definitions_compiler = SolutionDefinitionsCompiler.new(
  course: course,
  solutions_directory: solutions_dir
)

first_stage_solutions_compiler = FirstStageSolutionsCompiler.new(
  course: course,
  starters_directory: compiled_starters_dir,
  solutions_directory: solutions_dir
)

first_stage_explanations_compiler = FirstStageExplanationsCompiler.new(
  course: course,
  starters_directory: compiled_starters_dir,
  solutions_directory: solutions_dir
)

if language_filter
  starter_template_compiler.compile_for_language(language_filter)
  first_stage_solutions_compiler.compile_for_language(language_filter)
  first_stage_explanations_compiler.compile_for_language(language_filter)
  solution_diffs_compiler.compile_for_language(language_filter)
  solution_definitions_compiler.compile_for_language(language_filter)
else
  starter_template_compiler.compile_all
  first_stage_solutions_compiler.compile_all
  first_stage_explanations_compiler.compile_all
  solution_diffs_compiler.compile_all
  solution_definitions_compiler.compile_all
end

