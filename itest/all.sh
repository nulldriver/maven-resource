#!/bin/bash

set -e

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

source $BASE_DIR/test/helpers.sh

# Start Nexus
# exports REPO_DOMAIN
source $BASE_DIR/itest/nexus/nexus.sh

# 1.0.0-20170328.031519-19
readonly UNIQUE_SNAPSHOT_PATTERN="\-[0-9]{8}\.[0-9]{6}-[0-9]{1,}"
readonly SOURCE_URL=https://$REPO_DOMAIN/repository/maven-releases
readonly SOURCE_SNAPSHOT_URL=https://$REPO_DOMAIN/repository/maven-snapshots
readonly SOURCE_USERNAME=admin
readonly SOURCE_PASSWORD=admin123
readonly SOURCE_SKIP_CERT_CHECK=false
readonly SOURCE_REPOSITORY_CERT=$(openssl s_client -connect $REPO_DOMAIN -showcerts </dev/null 2>/dev/null|openssl x509 -outform PEM)
readonly SOURCE_DISABLE_REDEPLOY=false

it_can_deploy_snapshot_using_url() {

  local project=$BASE_DIR/test/fixtures/project
  local version=1.0.0-SNAPSHOT
  local debug=false

  REPO_URL=$SOURCE_SNAPSHOT_URL
  REPO_SNAPSHOT_URL=

  deploy_artifact_to_manager_with_pom $project $version $debug | jq -r '.version.version' | grep -oEq "$UNIQUE_SNAPSHOT_PATTERN"
}

it_can_deploy_snapshot_using_snapshot_url() {

  local project=$BASE_DIR/test/fixtures/project
  local version=1.0.0-SNAPSHOT
  local debug=false

  REPO_URL=
  REPO_SNAPSHOT_URL=$SOURCE_SNAPSHOT_URL

  deploy_artifact_to_manager_with_pom $project $version $debug | jq -r '.version.version' | grep -oEq "$UNIQUE_SNAPSHOT_PATTERN"
}

it_can_deploy_snapshot_using_both_urls() {

  local project=$BASE_DIR/test/fixtures/project
  local version=1.0.0-SNAPSHOT
  local debug=false

  REPO_URL=$SOURCE_URL
  REPO_SNAPSHOT_URL=$SOURCE_SNAPSHOT_URL

  deploy_artifact_to_manager_with_pom $project $version $debug | jq -r '.version.version' | grep -oEq "$UNIQUE_SNAPSHOT_PATTERN"
}

it_can_deploy_release() {

  local project=$BASE_DIR/test/fixtures/project
  local version=$1
  local debug=false

  REPO_URL=$SOURCE_URL
  REPO_SNAPSHOT_URL=

  deploy_artifact_to_manager_with_pom $project $version $debug | jq -e --arg version $version \
  '
    .version == {version: $version}
  '
}

it_can_check_snapshot_using_url() {

  local version=1.0.0-SNAPSHOT
  local debug=false

  REPO_URL=$SOURCE_SNAPSHOT_URL
  REPO_SNAPSHOT_URL=

  check_artifact_from_manager $version $debug | jq -r '.[].version' | grep -oEq "$UNIQUE_SNAPSHOT_PATTERN"
}

it_can_check_snapshot_using_snapshot_url() {

  local version=1.0.0-SNAPSHOT
  local debug=false

  REPO_URL=
  REPO_SNAPSHOT_URL=$SOURCE_SNAPSHOT_URL

  check_artifact_from_manager $version $debug | jq -r '.[].version' | grep -oEq "$UNIQUE_SNAPSHOT_PATTERN"
}

it_can_check_snapshot_using_both_urls() {

  local version=1.0.0-SNAPSHOT
  local debug=false

  REPO_URL=$SOURCE_URL
  REPO_SNAPSHOT_URL=$SOURCE_SNAPSHOT_URL

  check_artifact_from_manager $version $debug | jq -r '.[].version' | grep -oEq "$UNIQUE_SNAPSHOT_PATTERN"
}

it_can_check_release() {

  local version=$1
  local latestVersion=$2
  local debug=false

  REPO_URL=$SOURCE_URL
  REPO_SNAPSHOT_URL=$SOURCE_SNAPSHOT_URL

  check_artifact_from_manager $version $debug | jq -e --arg version "$version" --arg latestVersion "$latestVersion" \
  '
    . == [
      {version: $version},
      {version: $latestVersion}
    ]
  '
}

# Run tests using repository_cert
REPO_USERNAME=$SOURCE_USERNAME
REPO_PASSWORD=$SOURCE_PASSWORD
REPO_CERT=$SOURCE_REPOSITORY_CERT
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

echo -e '\e[32mall tests passed!\e[0m'
