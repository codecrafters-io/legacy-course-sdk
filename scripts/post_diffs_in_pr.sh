set -ue

marker_text="diffs_comment_marker"

function file_exists {
	local obj="$1"

	git cat-file -e "$obj" 2>/dev/null
}

function get_file {
	local obj="$1"

	file_exists "$obj" &&
		git --no-pager show "$obj"
}

function wrap_file {
	local obj="$1"

	file_exists "$obj" && {
		echo '```diff'
		get_file "$obj"
		echo '```'
		echo
	} || true
}

function collapsed {
	local summary="$1"
	local full="$2"

	echo "<details>"
	echo "<summary>$summary</summary>"
	echo
	echo "$full"
	echo "</details>"
	echo
}

function collapsed_file {
	local sum="$1"
	local obj="$2"

	local content=`wrap_file "$obj"`
	collapsed "$sum" "$content"
}

function print_both {
	local file="$1"
	local old="$2"
	local new="$3"

	echo file changed $file

	collapsed_file "old content" "$old"

	collapsed_file "new content" "$new"
}

function print_old {
	local file="$1"
	local old="$2"

	echo file removed $file

	collapsed_file "content" "$old"
}

function print_new {
	local file="$1"
	local new="$2"

	echo file created $file

	collapsed_file "content" "$new"
}

function comment_text {
	local base_ref="$1"
	local ref="$2"

	local langs=( `ls solutions` )
	local stages=( `yq '.stages[].slug' course-definition.yml` )

	for lang in "${langs[@]}"; do
		local lang_files=( ` git diff --name-only "$base_ref" "$ref" solutions/"$lang"/*/diff/**.diff ` )

		test 0 -eq "${#lang_files[@]}" && continue

		echo "## $lang"
		echo

		for stage in "${stages[@]}"; do
			local files=( ` git diff --name-only "$base_ref" "$ref" solutions/"$lang"/"$stage"/diff/**.diff ` )

			test 0 -eq "${#files[@]}" && continue

			echo "### $stage"

			for f in "${files[@]}"; do
				old="$base_ref:$f"
				new="$ref:$f"

				if file_exists "$old" && file_exists "$new"; then
					print_both "$f" "$old" "$new"
				elif file_exists "$old"; then
					print_old "$f" "$old"
				elif file_exists "$new"; then
					print_new "$f" "$new"
				else
					echo WTF; exit 1
				fi
			done
		done
	done

	echo
	echo "---"
	echo '`'"diff $base_ref $ref"'`'
	echo "_Posted by post_diffs_in_pr [codecrafters](https://github.com/codecrafters-io) Bot_"
	echo "_${marker_text}_"
}

function find_comment {
	curl -s "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${GITHUB_EVENT_NUMBER}/comments" |
		jq '[.[] | select(.user.type == "Bot" and (.body | contains("'"$marker_text"'")))][:1] | .[] | .id'
}

function comment_object {
	comment_text "$GITHUB_BASE_REF_SHA" "$GITHUB_REF_SHA" | jq -sR '{body: .}'
}

function create_comment {
	curl -sv \
		-X POST \
		-H "Authorization: Bearer ${GITHUB_TOKEN}" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${GITHUB_EVENT_NUMBER}/comments" \
		-d @<(comment_object)
}

function update_comment {
	local comment_id="$1"

	curl -sv \
		-X PATCH \
		-H "Authorization: Bearer ${GITHUB_TOKEN}" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/comments/$comment_id" \
		-d @<(comment_object)
}

function make_comment {
	comment_id=`find_comment`

	test -z "$comment_id" && create_comment || update_comment "$comment_id"
}

cd $REPO_PATH

make_comment
