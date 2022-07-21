require_relative "../lib/solution_definitions_compiler"
require_relative "../lib/models"

solution_definitions_compiler = SolutionDefinitionsCompiler.new(
  course: Course.load_from_file("../course-definition.yml"),
  solutions_directory: "../solutions"
)

solution_definitions_compiler.compile_all
