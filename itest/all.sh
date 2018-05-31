#!/bin/bash

set -eu
set -o pipefail

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

source $BASE_DIR/test/helpers.sh

# Defaults to local Nexus server (override by exporting your own vars before running this script)
: "${MVN_REPO_URL:=https://localhost:8081/repository/maven-releases}"
: "${MVN_SNAPSHOT_URL:=https://localhost:8081/repository/maven-snapshots}"
: "${MVN_USERNAME:=admin}"
: "${MVN_PASSWORD:=admin123}"
: "${MVN_SKIP_CERT_CHECK:=true}"
: "${MVN_REPO_CERT:=}"
: "${MVN_DISABLE_REDEPLOY:=false}"

# 1.0.0-20170328.031519-19
readonly UNIQUE_SNAPSHOT_PATTERN="\-[0-9]{8}\.[0-9]{6}-[0-9]{1,}"

it_can_deploy_snapshot_using_url() {

  local project=$BASE_DIR/test/fixtures/project
  local version=1.0.0-SNAPSHOT
  local debug=false

  REPO_URL=$MVN_SNAPSHOT_URL
  REPO_SNAPSHOT_URL=

  deploy_artifact_to_manager_with_pom $project $version $debug | jq -r '.version.version' | grep -oEq "$UNIQUE_SNAPSHOT_PATTERN"
}

it_can_deploy_snapshot_using_snapshot_url() {

  local project=$BASE_DIR/test/fixtures/project
  local version=1.0.0-SNAPSHOT
  local debug=false

  REPO_URL=
  REPO_SNAPSHOT_URL=$MVN_SNAPSHOT_URL

  deploy_artifact_to_manager_with_pom $project $version $debug | jq -r '.version.version' | grep -oEq "$UNIQUE_SNAPSHOT_PATTERN"
}

it_can_deploy_snapshot_using_both_urls() {

  local project=$BASE_DIR/test/fixtures/project
  local version=1.0.0-SNAPSHOT
  local debug=false

  REPO_URL=$MVN_REPO_URL
  REPO_SNAPSHOT_URL=$MVN_SNAPSHOT_URL

  deploy_artifact_to_manager_with_pom $project $version $debug | jq -r '.version.version' | grep -oEq "$UNIQUE_SNAPSHOT_PATTERN"
}

it_can_deploy_release() {

  local project=$BASE_DIR/test/fixtures/project
  local version=$1
  local debug=false

  REPO_URL=$MVN_REPO_URL
  REPO_SNAPSHOT_URL=

  deploy_artifact_to_manager_with_pom $project $version $debug | jq -e --arg version $version \
  '
    .version == {version: $version}
  '
}

it_can_check_snapshot_using_url() {

  local version=1.0.0-SNAPSHOT
  local debug=false

  REPO_URL=$MVN_SNAPSHOT_URL
  REPO_SNAPSHOT_URL=

  check_artifact_from_manager $version $debug | jq -r '.[].version' | grep -oEq "$UNIQUE_SNAPSHOT_PATTERN"
}

it_can_check_snapshot_using_snapshot_url() {

  local version=1.0.0-SNAPSHOT
  local debug=false

  REPO_URL=
  REPO_SNAPSHOT_URL=$MVN_SNAPSHOT_URL

  check_artifact_from_manager $version $debug | jq -r '.[].version' | grep -oEq "$UNIQUE_SNAPSHOT_PATTERN"
}

it_can_check_snapshot_using_both_urls() {

  local version=1.0.0-SNAPSHOT
  local debug=false

  REPO_URL=$MVN_REPO_URL
  REPO_SNAPSHOT_URL=$MVN_SNAPSHOT_URL

  check_artifact_from_manager $version $debug | jq -r '.[].version' | grep -oEq "$UNIQUE_SNAPSHOT_PATTERN"
}

it_can_check_release() {

  local version=$1
  local latestVersion=$2
  local debug=false

  REPO_URL=$MVN_REPO_URL
  REPO_SNAPSHOT_URL=$MVN_SNAPSHOT_URL

  check_artifact_from_manager $version $debug | jq -e --arg version "$version" --arg latestVersion "$latestVersion" \
  '
    . == [
      {version: $version},
      {version: $latestVersion}
    ]
  '
}

# Run tests using repository_cert
REPO_USERNAME=$MVN_USERNAME
REPO_PASSWORD=$MVN_PASSWORD
REPO_CERT=$MVN_REPO_CERT
REPO_SKIP_CERT_CHECK=
REPO_DISABLE_REDEPLOY=

#---
run it_can_deploy_snapshot_using_url
run it_can_deploy_snapshot_using_snapshot_url
run it_can_deploy_snapshot_using_both_urls

#---
version1="1.0.$UNIQUE_ID" && increment_unique_id
run it_can_deploy_release $version1

REPO_DISABLE_REDEPLOY=true
it_can_deploy_release $version1
REPO_DISABLE_REDEPLOY=

#---
version2="1.0.$UNIQUE_ID" && increment_unique_id
run it_can_deploy_release $version2

REPO_DISABLE_REDEPLOY=true
it_can_deploy_release $version2
REPO_DISABLE_REDEPLOY=

#---
version3="1.0.$UNIQUE_ID" && increment_unique_id
run it_can_deploy_release $version3

REPO_DISABLE_REDEPLOY=true
it_can_deploy_release $version3
REPO_DISABLE_REDEPLOY=

#---
run it_can_check_snapshot_using_url
run it_can_check_snapshot_using_snapshot_url
run it_can_check_snapshot_using_both_urls
run it_can_check_release $version2 $version3

printf '\e[32mall tests passed!\e[0m'
