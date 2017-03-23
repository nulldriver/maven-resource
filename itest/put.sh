#!/bin/bash

set -e

source $(dirname $0)/../test/helpers.sh

# Start Nexus
$(dirname $0)/nexus/nexus.sh
# todo: update release repo to allow redeploy to maven-releases to support multiple
#       test runs. As it stands right now, you have to do that in the UI

dockerMachineIp=$(docker-machine ip)

repo_url=https://$dockerMachineIp:8443/repository/maven-releases/
repo_snapshot_url=https://$dockerMachineIp:8443/repository/maven-snapshots/
repo_username=admin
repo_password=admin123
repo_cert=$(openssl s_client -connect $dockerMachineIp:8443 -showcerts </dev/null 2>/dev/null|openssl x509 -outform PEM)

it_can_deploy_release_to_manager_without_pom() {

  local src=$(mktemp -d $TMPDIR/out-src.XXXXXX)
  local version=1.0.0-rc.0

  deploy_without_pom_with_credentials $version $repo_username $repo_password "$repo_cert" $src $repo_url $repo_snapshot_url | jq -e "
    .version == {version: $(echo $version | jq -R .)}
  "
}

it_can_deploy_snapshot_to_manager_without_pom() {

  local src=$(mktemp -d $TMPDIR/out-src.XXXXXX)
  local version=1.0.0-rc.0-SNAPSHOT

  deploy_without_pom_with_credentials $version $repo_username $repo_password "$repo_cert" $src $repo_url $repo_snapshot_url | jq -e "
    .version == {version: $(echo $version | jq -R .)}
  "
}

# it_can_deploy_release_to_manager_with_pom() {
#
#   local src=$(mktemp -d $TMPDIR/out-src.XXXXXX)
#
#   mkdir $src/project
#   cp $(dirname $0)/resources/pom-release.xml $src/project/pom.xml
#
#   local pom=$src/project/pom.xml
#   local version=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='version']/text()" $pom)
#
#   deploy_with_pom_with_credentials $repo_url $pom $repo_username $repo_password "$repo_cert" $src | jq -e "
#     .version == {version: $(echo $version | jq -R .)}
#   "
# }

# it_can_deploy_snapshot_to_manager_with_pom() {
#
#   local src=$(mktemp -d $TMPDIR/out-src.XXXXXX)
#
#   mkdir $src/project
#   cp $(dirname $0)/resources/pom-snapshot.xml $src/project/pom.xml
#
#   local pom=$src/project/pom.xml
#   local version=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='version']/text()" $pom)
#
#   deploy_with_pom_with_credentials $repo_url $pom $repo_username $repo_password "$repo_cert" $src | jq -e "
#     .version == {version: $(echo $version | jq -R .)}
#   "
# }

run it_can_deploy_release_to_manager_without_pom
run it_can_deploy_snapshot_to_manager_without_pom
# run it_can_deploy_release_to_manager_with_pom
# run it_can_deploy_snapshot_to_manager_with_pom
