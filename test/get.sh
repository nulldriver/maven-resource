#!/bin/bash

set -e

source $(dirname $0)/helpers.sh

it_can_get_artifact() {

  local src=$(mktemp -d $TMPDIR/in-src.XXXXXX)

  mkdir -p $src/.m2/repository

  local url=file://$src/.m2/repository
  local artifact=org.seleniumhq.selenium.server:selenium-server:jar:standalone
  local version=1.0-beta-2

  get_artifact $url $artifact $version $src | jq -e "
    .version == {version: $(echo $version | jq -R .)}
  "

  # TODO: Validate $src/$file exists
  # local file=$(to_filename $artifact $version)
  # [ ! -f "$file" ]
}

run it_can_get_artifact
