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

function has_diffs {
	local base_ref="$1"
	local ref="$2"

	! git diff --quiet "$base_ref" "$ref" solutions/**/diff/**.diff
}

function has_diffs_current {
	has_diffs "$GITHUB_BASE_REF_SHA" "$GITHUB_REF_SHA"
}

function comment_text {
	local base_ref="$1"
	local ref="$2"

	local langs=( `ls solutions` )
	local stages=( `yq '.stages[].slug' course-definition.yml` )

	for lang in "${langs[@]}"; do
		local lang_files=( ` git diff --name-only "$base_ref" "$ref" solutions/"$lang"/*/diff/**.diff ` )

		test 0 -eq "${#lang_files[@]}" && continue

		local stage_num=0

		for stage in "${stages[@]}"; do
			stage_num=`expr $stage_num + 1`

			local files=( ` git diff --name-only "$base_ref" "$ref" solutions/"$lang"/*"$stage"/diff/**.diff ` )

			test 0 -eq "${#files[@]}" && continue

			echo "### Stage $stage_num: $stage ($lang)"
			echo

			for f in "${files[@]}"; do
				old="$base_ref:$f"
				new="$ref:$f"

				echo '`'$f'`'

				file_exists "$old" && collapsed_file "old content" "$old"
				file_exists "$new" && collapsed_file "new content" "$new"
			done
		done
	done

	echo
	echo "---"
	echo "Posted via [course-sdk](https://github.com/codecrafters-io/course-sdk/blob/$SDK_REF/.github/workflows/post-diffs-in-pr.yml)."
	echo "<!-- diff $base_ref $ref -->"
	echo "<!-- ${marker_text} -->"
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

function delete_comment {
	local comment_id="$1"

	curl -sv \
		-X DELETE \
		-H "Authorization: Bearer ${GITHUB_TOKEN}" \
		"https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/comments/$comment_id"
}

function make_comment {
	comment_id=`find_comment`

	if has_diffs_current; then
		test -z "$comment_id" && create_comment || update_comment "$comment_id"
	elif test -n "$comment_id"; then
		delete_comment "$comment_id"
	fi
}

cd $REPO_PATH

make_comment
