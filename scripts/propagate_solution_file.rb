# Usage: ruby scripts/propagate_solution_file.rb <course_dir> filename

require "fileutils"

require_relative "../lib/models"

course_dir = ARGV[0]
filename = ARGV[1]

unless course_dir && filename
  puts "Usage: ruby scripts/propagate_changes.rb <course-directory> <filename>"
  exit 1
end

course = Course.load_from_dir(course_dir)

Dir.foreach(course.solutions_dir) do |language_slug|
  next if language_slug == "." || language_slug == ".."

  Dir.foreach(File.join(course.solutions_dir, language_slug)) do |stage_number_and_slug|
    next if stage_number_and_slug == "." || stage_number_and_slug == ".."
    next if stage_number_and_slug == "01-#{course.first_stage.slug}"

    FileUtils.cp(
      File.join(course.solutions_dir, language_slug, "01-#{course.first_stage.slug}", "code", filename),
      File.join(course.solutions_dir, language_slug, stage_number_and_slug, "code", filename)
    )
  end
end

