#!/bin/bash

set -e

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

source $BASE_DIR/test/helpers.sh

# Start Nexus
# exports REPO_DOMAIN
source $BASE_DIR/itest/nexus/nexus.sh

REPO_URL=https://$REPO_DOMAIN/repository/maven-releases
REPO_SNAPSHOT_URL=https://$REPO_DOMAIN/repository/maven-snapshots
REPO_USERNAME=admin
REPO_PASSWORD=admin123
REPO_CERT=$(openssl s_client -connect $REPO_DOMAIN -showcerts </dev/null 2>/dev/null|openssl x509 -outform PEM)

# 1.0.0-20170328.031519-19
readonly UNIQUE_SNAPSHOT_PATTERN="\-[0-9]{8}\.[0-9]{6}-[0-9]{1,}"

it_can_deploy_snapshot_to_manager_with_pom() {

  local project=$BASE_DIR/test/fixtures/project
  local version=1.0.0-SNAPSHOT
  local debug=false

  local snapshot_version=$(deploy_artifact_to_manager_with_pom $project $version $debug | jq -r '.version.version')
  local snapshot_date=$(env TZ=UTC date '+%Y%m%d.')

  [ $(echo "$snapshot_version" | grep -oE "$UNIQUE_SNAPSHOT_PATTERN") ]
}

it_can_deploy_releases_to_manager_with_pom() {

  local project=$BASE_DIR/test/fixtures/project
  local version=
  local debug=false

  version=1.0.0
  deploy_artifact_to_manager_with_pom $project $version $debug | \
  jq -e \
  --arg version $version \
  '
    .version == {version: $version}
  '

  version=1.0.1
  deploy_artifact_to_manager_with_pom $project $version $debug | \
  jq -e \
  --arg version $version \
  '
    .version == {version: $version}
  '

  version=1.0.2
  deploy_artifact_to_manager_with_pom $project $version $debug | \
  jq -e \
  --arg version $version \
  '
    .version == {version: $version}
  '
}

it_can_check_snapshot_from_manager() {

  local version=1.0.0-SNAPSHOT
  local debug=false

  local snapshot_version=$(check_artifact_from_manager $version $debug | jq -r '.[].version')
  local snapshot_date=$(env TZ=UTC date '+%Y%m%d.')

  [ $(echo "$snapshot_version" | grep -oE "$UNIQUE_SNAPSHOT_PATTERN") ]
}

it_can_check_release_from_manager() {

  local version=1.0.1
  local debug=false

  check_artifact_from_manager $version $debug | \
  jq -e \
  --arg version $version \
  '
    . == [
      {version: $version},
      {version: "1.0.2"}
    ]
  '
}

run it_can_deploy_snapshot_to_manager_with_pom
run it_can_deploy_releases_to_manager_with_pom
run it_can_check_snapshot_from_manager
run it_can_check_release_from_manager

echo -e '\e[32mall tests passed!\e[0m'
