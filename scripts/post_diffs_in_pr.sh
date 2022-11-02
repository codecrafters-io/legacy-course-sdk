set -ue

marker_text="diffs_comment_marker"

function file_exists {
	local obj="$1"

	git cat-file -e "$obj" 2>/dev/null
}

function get_file {
	local obj="$1"

	file_exists "$obj" &&
		echo git --no-pager show "$obj"
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
	echo "$full"
	echo "</details>"
}

function print_both {
	local file=$1
	local old="$2"
	local new="$3"

	echo file changed $file

	local content=`wrap_file "$old"`
	collapsed "old content" "$content"

	local content=`wrap_file "$new"`
	collapsed "new content" "$content"
}

function print_old {
	local file=$1
	local old="$2"

	echo file removed $f

	local content=`wrap_file "$old"`
	collapsed "content" "$content"
}

function print_new {
	local file=$1
	local new="$2"

	echo file created $f

	local content=`wrap_file "$new"`
	collapsed "content" "$content"
}

function comment_text {
	local base_ref="$1"
	local ref="$2"

	local files=( ` git diff --name-only "$base_ref" "$ref" solutions/*/*/diff/**.diff ` )

	for f in "${files[@]}"; do
		old="$base_ref:$f"
		new="$ref:$f"

		file_exists "$old" && file_exists "$new" && print_both "$f" "$old" "$new" || {
			file_exists "$old" && print_old "$f" "$old" || {
				file_exists "$new" && print_new "$f" "$new" || {
					echo WTF; exit 1
				}
			}
		}
	done

	echo
	echo $marker_text
}

function find_comment {
	curl -s "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${GITHUB_EVENT_NUMBER}/comments" | jq '.[] | select(.user.type == "Bot") | .id'
}

function comment_object {
	comment_text "$ARG_BASE_REF" "$ARG_REF" | jq -sR '{body: .}'
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

set +u

echo env vars
echo REPO_PATH=$REPO_PATH
echo GITHUB_TOKEN=$GITHUB_TOKEN
echo GITHUB_REPOSITORY=$GITHUB_REPOSITORY
echo GITHUB_EVENT_NUMBER=$GITHUB_EVENT_NUMBER
echo GITHUB_BASE_REF=$GITHUB_BASE_REF
echo GITHUB_REF=$GITHUB_REF
echo ARG_BASE_REF=$ARG_BASE_REF
echo ARG_REF=$ARG_REF

set -u

cd $REPO_PATH

#comment_object
make_comment
