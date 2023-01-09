#!/bin/sh
# Usage: scripts/compile_and_test.sh <course_dir> <language_slug> <optional:stage_slugs>
set -e

courseDir=$1
languageSlug=$2
stageSlugs=$3

if [ -z "$courseDir" ] || [ -z "$languageSlug" ]; then
  echo "Usage: scripts/compile_and_test.sh <course_dir> <language_slug> <optional:stage_slugs>"
  exit 1
fi

ruby scripts/compile.rb "$courseDir" "$languageSlug"
ruby scripts/test.rb "$courseDir" "$languageSlug" "$stageSlugs"