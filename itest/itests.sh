#!/bin/bash

set -eu
set -o pipefail

basedir="$(dirname "$0")"
. "$basedir/helpers.sh"

# Export these vars *before* running this script!
: "${MVN_REPO_URL:?}"
: "${MVN_REPO_USERNAME:?}"
: "${MVN_REPO_PASSWORD:?}"

# 1.0.0-20170328.031519-19
readonly UNIQUE_SNAPSHOT_PATTERN="\-[0-9]{8}\.[0-9]{6}-[0-9]{1,}"

it_can_return_an_empty_list_if_no_versions_available() {

  json=$(check_a_snapshot_and_return_the_unique_version "com.example:$(gen_artifact_id):jar")
  assert_equals "[]" "$json"
}

it_can_return_current_version_if_no_version_requested() {

  local artifact="com.example:$(gen_artifact_id):jar"

  json=$(put_a_snapshot_and_return_the_unique_version "$artifact")
  version_put=$(echo $json | jq -r '.version.version')
  assert_matches "$version_put" "$UNIQUE_SNAPSHOT_PATTERN"

  check_a_snapshot_and_return_the_unique_version "$artifact" | \
  jq -e \
  --arg version "$version_put" \
  '
    . == [{version: $version}]
  '
}

run it_can_return_an_empty_list_if_no_versions_available
run it_can_return_current_version_if_no_version_requested
