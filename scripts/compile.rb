# Usage: ruby scripts/compile.rb <course_dir> <language_slug>
require_relative "../lib/starter_template_compiler/compiler"
require_relative "../lib/solution_diffs_compiler"
require_relative "../lib/first_stage_solutions_compiler"
require_relative "../lib/first_stage_explanations_compiler"
require_relative "../lib/models"

course_dir = ARGV[0]
language_filter = ARGV[1]

unless course_dir
  puts "Usage: ruby scripts/compile.rb <course-directory> [language-filter]"
  exit 1
end

course = Course.load_from_dir(course_dir)

compilers = [
  StarterTemplateCompiler.new(course: course),
  FirstStageSolutionsCompiler.new(course: course),
  FirstStageExplanationsCompiler.new(course: course),
  SolutionDiffsCompiler.new(course: course),
]

if language_filter
  language = Language.find_by_slug!(language_filter)
  compilers.each { |compiler| compiler.compile_for_language(language) }
else
  compilers.each { |compiler| compiler.compile_all }
end

