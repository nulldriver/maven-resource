#!/bin/bash

set -e

source $(dirname $0)/helpers.sh

it_can_check() {

  local src=$(mktemp -d $TMPDIR/out-src.XXXXXX)

  local url=http://nexus.anvil.pcfdemo.com/repository/maven-public/
  local artifact=org.springframework:spring-core
  local version=4.2.0.RELEASE

  cat <<EOF | $resource_dir/check "$src" | tee /dev/stderr
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

run it_can_check
