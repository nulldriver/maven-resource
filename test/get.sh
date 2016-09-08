#!/bin/bash

set -e

source $(dirname $0)/helpers.sh

it_can_get_artifact() {

  local src=$(mktemp -d $TMPDIR/check-src.XXXXXX)

  local repository=$src/remote-repository
  mkdir -p $repository

  local url=file://$repository
  local artifact=org.seleniumhq.selenium.server:selenium-server:jar:standalone

  local ver=$(deploy_artifact $url $artifact "1.0.0-rc.1" $src)

  get_artifact $url $artifact $ver $src | jq -e "
    .version == {version: $(echo $ver | jq -R .)}
  "
}

run it_can_get_artifact
