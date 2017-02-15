#!/bin/bash

set -e

source $(dirname $0)/../test/helpers.sh

it_can_check_from_manager() {

  local src=$(mktemp -d $TMPDIR/check-src.XXXXXX)

  local protocol=https
  local hostname=nexus.anvil.pcfdemo.com
  local port=443

  local url=$protocol://$hostname:$port/repository/maven-public
  local artifact=org.springframework:spring-core
  local version=4.2.0.RELEASE

  openssl s_client -connect $hostname:$port -showcerts </dev/null 2>/dev/null|openssl x509 -outform PEM >$src/cert.pem

  # load cert into a variable and convert to a sinlge line string
  local repository_cert=$(cat $src/cert.pem | awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}')

  cat <<EOF | $resource_dir/check "$src" | tee /dev/stderr
  {
    "source": {
      "url": "$url",
      "artifact": "$artifact",
      "repository_cert": "$repository_cert"
    },
    "version": {
      "version": "$version"
    }
  }
EOF
}

run it_can_check_from_manager
