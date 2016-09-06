#!/bin/bash

set -e

source $(dirname $0)/helpers.sh

it_can_get() {

  local src=$(mktemp -d $TMPDIR/out-src.XXXXXX)

  local url=http://nexus.anvil.pcfdemo.com/repository/maven-public/
  local artifact=org.seleniumhq.selenium.server:selenium-server:jar:standalone
  local version=1.0-beta-2

  cat <<EOF | $resource_dir/in "$src" | tee /dev/stderr
  {
    "source": {
      "url": "$url",
      "artifact": "$artifact"
    },
    "version": {
      "version": "$version"
    }
  }
EOF
}

run it_can_get
