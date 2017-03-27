#!/bin/bash

set -e

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

source $BASE_DIR/test/helpers.sh

# Start Nexus
$BASE_DIR/itest/nexus/nexus.sh
# todo: update release repo to allow redeploy to maven-releases to support multiple
#       test runs. As it stands right now, you have to do that in the UI

DOCKER_MACHINE_IP=$(docker-machine ip)

REPO_URL=https://$DOCKER_MACHINE_IP:8443/repository/maven-releases
REPO_SNAPSHOT_URL=https://$DOCKER_MACHINE_IP:8443/repository/maven-snapshots
REPO_USERNAME=admin
REPO_PASSWORD=admin123
REPO_CERT=$(openssl s_client -connect $DOCKER_MACHINE_IP:8443 -showcerts </dev/null 2>/dev/null|openssl x509 -outform PEM)

it_can_deploy_snapshot_to_manager_with_pom() {

  local project=$BASE_DIR/test/fixtures/project-snapshot
  local version=1.0.0-SNAPSHOT

  local snapshot_version=$(deploy_artifact_to_manager_with_pom $project $version | jq -r '.version.version')
  local snapshot_date=$(date '+%Y%m%d.')

  [[ "$snapshot_version" = "${version%-SNAPSHOT}-$snapshot_date"* ]]
}

it_can_deploy_release_to_manager_with_pom() {

  local project=$BASE_DIR/test/fixtures/project-release
  local version=1.0.0

  deploy_artifact_to_manager_with_pom $project $version | \
  jq -e \
  --arg version $version \
  '
    .version == {version: $version}
  '
}

it_can_check_snapshot_from_manager() {

  local version=1.0.0-SNAPSHOT

  local snapshot_version=$(check_artifact_from_manager $version | jq -r '.[].version')
  local snapshot_date=$(date '+%Y%m%d.')

  [[ "$snapshot_version" = "${version%-SNAPSHOT}-$snapshot_date"* ]]
}

it_can_check_release_from_manager() {

  local version=1.0.0

  check_artifact_from_manager $version | \
  jq -e \
  --arg version $version \
  '
    . == [
      {version: $version}
    ]
  '
}

run it_can_deploy_snapshot_to_manager_with_pom
run it_can_deploy_release_to_manager_with_pom
run it_can_check_snapshot_from_manager
run it_can_check_release_from_manager

echo -e '\e[32mall tests passed!\e[0m'
