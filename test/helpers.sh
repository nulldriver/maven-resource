#!/bin/bash

set -e -u

set -o pipefail

export TMPDIR_ROOT=$(mktemp -d /tmp/mvn-tests.XXXXXX)
trap "rm -rf $TMPDIR_ROOT" EXIT

if [ -d /opt/resource ]; then
  resource_dir=/opt/resource
else
  resource_dir=$(cd $(dirname $0)/../assets && pwd)
fi

run() {
  export TMPDIR=$(mktemp -d ${TMPDIR_ROOT}/mvn-tests.XXXXXX)

  echo -e 'running \e[33m'"$@"$'\e[0m...'
  eval "$@" 2>&1 | sed -e 's/^/  /g'
  echo ""
}

create_version_file() {
  local version=$1
  local src=$2

  mkdir $src/version
  echo "$version" > $src/version/number

  echo version/number
}

deploy_without_pom_without_credentials() {

  local url=$1
  local version=$2
  local src=$3

  local version_file=$(create_version_file "$version" "$src")

  local groupId=org.some.group
  local artifactId=your-artifact
  local packaging=jar
  local file=build-output/$artifactId-*.$packaging

  # Mock the jar
  mkdir $src/build-output
  touch $src/build-output/$artifactId-$version.$packaging

  jq -n "{
    params: {
      file: $(echo $file | jq -R .),
      groupId: $(echo $groupId | jq -R .),
      artifactId: $(echo $artifactId | jq -R .),
      version_file: $(echo $version_file | jq -R .),
      packaging: $(echo $packaging | jq -R .)
    },
    source: {
      url: $(echo $url | jq -R .)
    }
  }" | $resource_dir/out "$src" | tee /dev/stderr
}

deploy_without_pom_with_credentials() {

  local url=$1
  local version=$2
  local username=$3
  local password=$4
  local repository_cert=$(echo "$5" | awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}')
  local src=$6

  local version_file=$(create_version_file "$version" "$src")

  local groupId=org.some.group
  local artifactId=your-artifact
  local packaging=jar
  local file=build-output/$artifactId-*.$packaging

  # Mock the jar
  mkdir $src/build-output
  touch $src/build-output/$artifactId-$version.$packaging

  cat <<EOF | $resource_dir/out "$src" | tee /dev/stderr
  {
    "params": {
      "file": "$file",
      "groupId": "$groupId",
      "artifactId": "$artifactId",
      "version_file": "$version_file",
      "packaging": "$packaging",
      "repository_cert": "$repository_cert"
    },
    "source": {
      "url": "$url",
      "username": "$username",
      "password": "$password"
    }
  }
EOF
}

deploy_with_pom_without_credentials() {

  local url=$1
  local pom=$2
  local src=$3

  local artifactId=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='artifactId']/text()" $pom)
  local packaging=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='packaging']/text()" $pom)
  local version=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='version']/text()" $pom)

  local file=build-output/$artifactId-*.$packaging

  # Mock the jar
  mkdir $src/build-output
  touch $src/build-output/$artifactId-$version.$packaging

  jq -n "{
    params: {
      file: $(echo $file | jq -R .),
      pom: $(echo $pom | jq -R .)
    },
    source: {
      url: $(echo $url | jq -R .)
    }
  }" | $resource_dir/out "$src" | tee /dev/stderr
}

deploy_with_pom_with_credentials() {

  local url=$1
  local pom=$2
  local username=$3
  local password=$4
  local repository_cert=$(echo "$5" | awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}')
  local src=$6

  local artifactId=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='artifactId']/text()" $pom)
  local packaging=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='packaging']/text()" $pom)
  local version=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='version']/text()" $pom)

  local file=build-output/$artifactId-*.$packaging

  # Mock the jar
  mkdir $src/build-output
  touch $src/build-output/$artifactId-$version.$packaging

  cat <<EOF | $resource_dir/out "$src" | tee /dev/stderr
  {
    "params": {
      "file": "$file",
      "pom": "$pom",
      "repository_cert": "$repository_cert"
    },
    "source": {
      "url": "$url",
      "username": "$username",
      "password": "$password"
    }
  }
EOF
}
