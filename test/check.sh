#!/bin/bash

set -e

source $(dirname $0)/helpers.sh

it_can_check_from_one_version() {

  local src=$(mktemp -d $TMPDIR/check-src.XXXXXX)

  local repository=$src/remote-repository
  mkdir -p $repository

  local url=file://$repository
  local artifact=ci.concourse.maven:maven-resource:jar:standalone

  local ver=$(deploy_artifact $url $artifact "1.0.0-rc.1" $src)

  check_artifact $url $artifact $ver $src | jq -e "
    . == [{version: $(echo $ver | jq -R .)}]
  "
}

it_can_check_from_three_versions() {

  local src=$(mktemp -d $TMPDIR/check-src.XXXXXX)

  local repository=$src/remote-repository
  mkdir -p $repository

  local url=file://$repository
  local artifact=ci.concourse.maven:maven-resource:jar:standalone

  local ver1=$(deploy_artifact $url $artifact "1.0.0-rc.1" $src)
  local ver2=$(deploy_artifact $url $artifact "1.0.0-rc.2" $src)
  local ver3=$(deploy_artifact $url $artifact "1.0.0-rc.3" $src)

  check_artifact $url $artifact $ver1 $src | jq -e "
    . == [
      {version: $(echo $ver1 | jq -R .)},
      {version: $(echo $ver2 | jq -R .)},
      {version: $(echo $ver3 | jq -R .)}
    ]
  "
}

it_can_check_latest_from_one_version() {

  local src=$(mktemp -d $TMPDIR/check-src.XXXXXX)

  local repository=$src/remote-repository
  mkdir -p $repository

  local url=file://$repository
  local artifact=ci.concourse.maven:maven-resource:jar:standalone

  local ver=$(deploy_artifact $url $artifact "1.0.0-rc.1" $src)

  check_artifact $url $artifact 'latest' $src | jq -e "
    . == [{version: $(echo $ver | jq -R .)}]
  "
}

it_can_check_latest_from_three_versions() {

  local src=$(mktemp -d $TMPDIR/check-src.XXXXXX)

  local repository=$src/remote-repository
  mkdir -p $repository

  local url=file://$repository
  local artifact=ci.concourse.maven:maven-resource:jar:standalone

  local ver1=$(deploy_artifact $url $artifact "1.0.0-rc.1" $src)
  local ver2=$(deploy_artifact $url $artifact "1.0.0-rc.2" $src)
  local ver3=$(deploy_artifact $url $artifact "1.0.0-rc.3" $src)

  check_artifact $url $artifact 'latest' $src | jq -e "
    . == [
      {version: $(echo $ver3 | jq -R .)}
    ]
  "
}

run it_can_check_from_one_version
run it_can_check_from_three_versions

it_can_check_latest_from_one_version
it_can_check_latest_from_three_versions
