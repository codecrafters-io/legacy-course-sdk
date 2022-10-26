# Usage: ruby scripts/propagate_solution_changes.rb <course_dir>
# TODO: This doesn't work yet!

require "tempfile"
require "tmpdir"

require_relative "../lib/models"

course_dir = ARGV[0]

unless course_dir
  puts "Usage: ruby scripts/propagate_changes.rb <course-directory>"
  exit 1
end

course = Course.load_from_dir(course_dir)

changed_files = `git -C #{course.dir} diff --name-only solutions/`.split("\n").map(&:strip)
changed_files += `git -C #{course.dir} diff --cached --name-only solutions/`.split("\n").map(&:strip)

if changed_files.empty?
  puts "No changes found. Make sure that there are changes to files in the solutions/ directory"
  exit 0
end

puts "Found #{changed_files.size} changed files: \n#{changed_files.map{ |filename| "  - #{filename}"}.join("\n")}"
puts ""

affected_languages_and_stages = changed_files.map { |filename| [filename.split("/")[1], filename.split("/")[2]] }.uniq

if affected_languages_and_stages.size != 1
  puts "Can only propagate changes for one language and one stage at a time. Found: #{affected_languages_and_stages}"
  exit 1
end

language_slug, changed_stage_slug = affected_languages_and_stages.first[0], affected_languages_and_stages.first[1]
changed_stage = course.stages.find { |stage| stage.slug == changed_stage_slug }

stages_to_propagate = course.stages_after(changed_stage)

puts "Will propagate changes from #{changed_stage.slug} to later stages for #{language_slug}: "
stages_to_propagate.each do |stage|
  puts "  - #{stage.slug}"
end
puts ""

begin
  puts "Confirm? (any key to proceed, CTRL+C to exit)"
  $stdin.gets.chomp
rescue Interrupt
  puts "Aborted"
  exit 1
end

changed_files.each do |changed_file|
  Dir.mktmpdir do |tempdir|
    user_patch_path = File.join(tempdir, "user_patch.diff")
    base_patch_path = File.join(tempdir, "base_patch.diff")
    combined_patch_path = File.join(tempdir, "combined_patch.diff")
    puts "Generating diff for #{changed_file}..."
    `git -C #{course.dir} diff #{changed_file} > #{user_patch_path}`
    `git -C #{course.dir} stash`

    absolute_changed_file_path = File.join(course.dir, changed_file)

    stages_to_propagate.each do |stage|
      file_to_change_path = File.join(course.dir, changed_file.sub(changed_stage.slug, stage.slug))

      if File.exist?(file_to_change_path)
        `diff -Naur #{absolute_changed_file_path} #{file_to_change_path} > #{base_patch_path}`
        `combinediff #{user_patch_path} #{base_patch_path} > #{combined_patch_path}`
        puts "Writing patch to #{file_to_change_path}..."
        `cp #{absolute_changed_file_path} #{file_to_change_path}`
        puts `patch -p1 #{file_to_change_path} #{combined_patch_path}`
      else
        puts "File #{file_to_change_path} does not exist. Skipping"
      end
    end

    `git -C #{course_dir} stash apply`
  end
end