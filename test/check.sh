#!/bin/bash

set -e

source $(dirname $0)/helpers.sh

it_can_check_from_one_version() {

  local src=$(mktemp -d $TMPDIR/check-src.XXXXXX)

  local repository=$src/remote-repository
  mkdir -p $repository

  local url=file://$repository
  local artifact=ci.concourse.maven:maven-resource:jar:standalone

  local ver=$(deploy_artifact $url $artifact '1.0.0-rc.1' $src)

  check_artifact $url $artifact $ver $src | \
  jq -e \
  --arg version $ver \
  '
    . == [{version: $version}]
  '
}

it_can_check_from_three_versions() {

  local src=$(mktemp -d $TMPDIR/check-src.XXXXXX)

  local repository=$src/remote-repository
  mkdir -p $repository

  local url=file://$repository
  local artifact=ci.concourse.maven:maven-resource:jar:standalone

  local version1=$(deploy_artifact $url $artifact '1.0.0-rc.1' $src)
  local version2=$(deploy_artifact $url $artifact '1.0.0-rc.2' $src)
  local version3=$(deploy_artifact $url $artifact '1.0.0-rc.3' $src)

  check_artifact $url $artifact $version2 $src | \
  jq -e \
  --arg version1 $version1 \
  --arg version2 $version2 \
  --arg version3 $version3 \
  '
    . == [
      {version: $version2},
      {version: $version3}
    ]
  '
}

it_can_check_latest_from_one_version() {

  local src=$(mktemp -d $TMPDIR/check-src.XXXXXX)

  local repository=$src/remote-repository
  mkdir -p $repository

  local url=file://$repository
  local artifact=ci.concourse.maven:maven-resource:jar:standalone

  local version=$(deploy_artifact $url $artifact '1.0.0-rc.1' $src)

  check_artifact $url $artifact 'latest' $src | \
  jq -e \
  --arg version $version \
  '
    . == [{version: $version}]
  '
}

it_can_check_latest_from_three_versions() {

  local src=$(mktemp -d $TMPDIR/check-src.XXXXXX)

  local repository=$src/remote-repository
  mkdir -p $repository

  local url=file://$repository
  local artifact=ci.concourse.maven:maven-resource:jar:standalone

  local version1=$(deploy_artifact $url $artifact '1.0.0-rc.1' $src)
  local version2=$(deploy_artifact $url $artifact '1.0.0-rc.2' $src)
  local version3=$(deploy_artifact $url $artifact '1.0.0-rc.3' $src)

  check_artifact $url $artifact 'latest' $src | \
  jq -e \
  --arg version $version3 \
  '
    . == [
      {version: $version}
    ]
  '
}

it_can_check_filtered_version_from_four_versions() {

  local src=$(mktemp -d $TMPDIR/check-src.XXXXXX)

  local repository=$src/remote-repository
  mkdir -p $repository

  local url=file://$repository
  local artifact=ci.concourse.maven:maven-resource:jar:standalone

  local version1=$(deploy_artifact $url $artifact '1.0.0-rc.1' $src)
  local version2=$(deploy_artifact $url $artifact '1.0.0-rc.2' $src)
  local version3=$(deploy_artifact $url $artifact '2.0.0-rc.1' $src)
  local version4=$(deploy_artifact $url $artifact '21.0.0-rc.1' $src)

  check_artifact_filtered $url $artifact 'latest' $src '1\.0\.0-.*' | \
  jq -e \
  --arg version $version2 \
  '
    . == [
      {version: $version}
    ]
  '
}

it_can_check_filtered_out_all_version() {

  local src=$(mktemp -d $TMPDIR/check-src.XXXXXX)

  local repository=$src/remote-repository
  mkdir -p $repository

  local url=file://$repository
  local artifact=ci.concourse.maven:maven-resource:jar:standalone

  local version1=$(deploy_artifact $url $artifact '1.0.0-rc.1' $src)
  local version2=$(deploy_artifact $url $artifact '1.0.0-rc.2' $src)

  check_artifact_filtered $url $artifact 'latest' $src '2\.0\.0-.*' | \
  jq -e \
  '
    . == [
    ]
  '
}

it_can_check_provided_version_is_not_latest_version_when_filtering() {

  local src=$(mktemp -d $TMPDIR/check-src.XXXXXX)

  local repository=$src/remote-repository
  mkdir -p $repository

  local url=file://$repository
  local artifact=ci.concourse.maven:maven-resource:jar:standalone

  local version1=$(deploy_artifact $url $artifact '1.0.0-rc.1' $src)
  local version2=$(deploy_artifact $url $artifact '1.0.0-rc.2' $src)
  local version3=$(deploy_artifact $url $artifact '1.0.0-rc.3' $src)

  check_artifact_filtered $url $artifact $version2 $src '1\.0\.0-.*' | \
  jq -e \
  --arg version1 $version1 \
  --arg version2 $version2 \
  --arg version3 $version3 \
  '
    . == [
      {version: $version2},
      {version: $version3}
    ]
  '
}

it_can_check_provided_version_is_latest_version_when_filtering() {

  local src=$(mktemp -d $TMPDIR/check-src.XXXXXX)

  local repository=$src/remote-repository
  mkdir -p $repository

  local url=file://$repository
  local artifact=ci.concourse.maven:maven-resource:jar:standalone

  local version1=$(deploy_artifact $url $artifact '1.0.0-rc.1' $src)
  local version2=$(deploy_artifact $url $artifact '1.0.0-rc.2' $src)

  check_artifact_filtered $url $artifact $version2 $src '1\.0\.0-.*' | \
  jq -e \
  --arg version1 $version1 \
  --arg version2 $version2 \
  '
    . == [
      {version: $version2}
    ]
  '
}

run it_can_check_from_one_version
run it_can_check_from_three_versions
run it_can_check_latest_from_one_version
run it_can_check_latest_from_three_versions
run it_can_check_filtered_version_from_four_versions
run it_can_check_filtered_out_all_version
run it_can_check_provided_version_is_not_latest_version_when_filtering
run it_can_check_provided_version_is_latest_version_when_filtering
