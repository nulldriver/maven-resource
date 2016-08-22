#!/bin/bash

set -e

source $(dirname $0)/helpers.sh

# Export these vars, or let the script prompt you for them
#export MAVEN_RELEASES_URL=http://myrepo.com/repository/releases/
#export MAVEN_SNAPSHOTS_URL=http://myrepo.com/repository/snapshots/
#export MAVEN_REPO_USERNAME=username
#export MAVEN_REPO_PASSWORD=password
#export MAVEN_REPOSITORY_CERT=$(cat /path/to/cert)

if [ -z "$MAVEN_RELEASES_URL" ]; then
  echo "Maven Releases Repo URL: "
  read -r MAVEN_RELEASES_URL
fi
if [ -z "$MAVEN_SNAPSHOTS_URL" ]; then
  echo "Maven Snapshots Repo URL: "
  read -r MAVEN_SNAPSHOTS_URL
fi
if [ -z "$MAVEN_REPO_USERNAME" ]; then
  echo "Maven Repo Username: "
  read -r MAVEN_REPO_USERNAME
fi
if [ -z "$MAVEN_REPO_PASSWORD" ]; then
  echo "Maven Repo Password: "
  read -r MAVEN_REPO_PASSWORD
fi

it_can_deploy_release_to_manager_without_pom() {

  local src=$(mktemp -d $TMPDIR/out-src.XXXXXX)
  local url=$MAVEN_RELEASES_URL
  local version=1.0.0-rc.0
  local username=$MAVEN_REPO_USERNAME
  local password=$MAVEN_REPO_PASSWORD
  local repository_cert=$MAVEN_REPOSITORY_CERT

  deploy_without_pom_with_credentials $url $version $username $password "$repository_cert" $src | jq -e "
    .version == {version: $(echo $version | jq -R .)}
  "
}

it_can_deploy_snapshot_to_manager_without_pom() {

  local src=$(mktemp -d $TMPDIR/out-src.XXXXXX)
  local url=$MAVEN_SNAPSHOTS_URL
  local version=1.0.0-rc.0-SNAPSHOT
  local username=$MAVEN_REPO_USERNAME
  local password=$MAVEN_REPO_PASSWORD
  local repository_cert=$MAVEN_REPOSITORY_CERT

  deploy_without_pom_with_credentials $url $version $username $password "$repository_cert" $src | jq -e "
    .version == {version: $(echo $version | jq -R .)}
  "
}

it_can_deploy_release_to_manager_with_pom() {

  local src=$(mktemp -d $TMPDIR/out-src.XXXXXX)

  mkdir $src/project
  cp $(dirname $0)/resources/pom-release.xml $src/project/pom.xml

  local url=$MAVEN_RELEASES_URL
  local pom=$src/project/pom.xml
  local version=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='version']/text()" $pom)
  local username=$MAVEN_REPO_USERNAME
  local password=$MAVEN_REPO_PASSWORD
  local repository_cert=$MAVEN_REPOSITORY_CERT

  deploy_with_pom_with_credentials $url $pom $username $password "$repository_cert" $src | jq -e "
    .version == {version: $(echo $version | jq -R .)}
  "
}

it_can_deploy_snapshot_to_manager_with_pom() {

  local src=$(mktemp -d $TMPDIR/out-src.XXXXXX)

  mkdir $src/project
  cp $(dirname $0)/resources/pom-snapshot.xml $src/project/pom.xml

  local url=$MAVEN_SNAPSHOTS_URL
  local pom=$src/project/pom.xml
  local version=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='version']/text()" $pom)
  local username=$MAVEN_REPO_USERNAME
  local password=$MAVEN_REPO_PASSWORD
  local repository_cert=$MAVEN_REPOSITORY_CERT

  deploy_with_pom_with_credentials $url $pom $username $password "$repository_cert" $src | jq -e "
    .version == {version: $(echo $version | jq -R .)}
  "
}

run it_can_deploy_release_to_manager_without_pom
run it_can_deploy_snapshot_to_manager_without_pom
run it_can_deploy_release_to_manager_with_pom
run it_can_deploy_snapshot_to_manager_with_pom
