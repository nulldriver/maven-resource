#!/bin/bash

set -e

source $(dirname $0)/helpers.sh

it_can_get_artifact() {

  local src=$(mktemp -d $TMPDIR/check-src.XXXXXX)

  local repository=$src/remote-repository
  mkdir -p $repository

  local url=file://$repository
  local artifact=ci.concourse.maven:maven-resource:jar:standalone

  local version=$(deploy_artifact $url $artifact '1.0.0-rc.1' $src)

  get_artifact $url $artifact $version $src | \
  jq -e \
  --arg version $version \
  '
    .version == {version: $version}
  '
}

run it_can_get_artifact
