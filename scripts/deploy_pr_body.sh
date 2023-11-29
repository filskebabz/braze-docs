#!/bin/bash

# TODO: write script description + rewrite all command descriptions
# TODO: cleanup/reformat script using bash scripting best practices
# TODO: add 'gh' and 'jq' to dev dependencies
# TODO: create how to guide and add to confluence

# Fetch PR list
PR_LIST=$(gh pr list --state all --limit 1000 --json mergedAt,number,title,url)

# Filter out PRs with 'mergedAt' as null and sort by date in descending order
SORTED_PR_LIST=$(echo "$PR_LIST" | jq '[.[] | select(.mergedAt != null)] | sort_by(.mergedAt) | reverse')

# Find the index of the most recent "Deploy -" PR
DEPLOY_INDEX=$(echo "$SORTED_PR_LIST" \
  | jq -r 'to_entries | map(select(.value.title | startswith("Deploy -"))) | .[0].key')

# Remove the last deploy entry and all entries below it
FILTERED_PR_LIST=$(echo "$SORTED_PR_LIST" | jq --argjson DEPLOY_INDEX "$DEPLOY_INDEX" 'del(.[$DEPLOY_INDEX:])')

# Output the result in Markdown format with modified title
echo "$FILTERED_PR_LIST" \
  | jq -r '.[] | "- [" + (.number|tostring) + "](" + .url + ") " + (.title | gsub("BD-[^ ]+"; ""))' \
  | tr -s ' ' | sort -t "[" -k2,2n \
  > deploy_pr_body.md
