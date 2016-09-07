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

# it_can_check() {
#
#   local src=$(mktemp -d $TMPDIR/check-src.XXXXXX)
#
#   local url=file://$src/.m2/repository
#   local artifact=org.seleniumhq.selenium.server:selenium-server:jar:standalone
#   local version=1.0-beta-2
#
#   check_artifact $url $artifact $version $src | jq -e "
#     .version == {version: $(echo $version | jq -R .)}
#   "
# }

run it_can_check
