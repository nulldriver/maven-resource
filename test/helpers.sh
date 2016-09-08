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

source $resource_dir/common.sh

run() {
  export TMPDIR=$(mktemp -d ${TMPDIR_ROOT}/mvn-tests.XXXXXX)

  echo -e 'running \e[33m'"$@"$'\e[0m...'
  eval "$@" 2>&1 | sed -e 's/^/  /g'
  echo ""
}

to_filename() {
  local artifact=$1
  local version=$2

  local artifactId=$(get_artifact_id $artifact)
  local packaging=$(get_packaging $artifact)
  local classifier=$(get_classifier $artifact)
  [ -n "$classifier" ] && classifier="-${classifier}"

  echo $artifactId-$version$classifier.$packaging
}

deploy_artifact() {
  local artifact=$1
  local version=$2
  local src=$3

  local groupId=$(get_group_id $artifact)
  local artifactId=$(get_artifact_id $artifact)
  local packaging=$(get_packaging $artifact)
  local classifier=$(get_classifier $artifact)

  local file=$src/$(to_filename $artifact $version)
  echo "dummy jar (maven won't deploy a zero length file)" > $file

  local args="
    -Dfile=$file
    -Durl=file://$src
    -DgroupId=$(get_group_id $artifact)
    -DartifactId=$(get_artifact_id $artifact)
    -Dversion=$version
  "
  [ -n "$classifier" ] && args="$args -Dclassifier=$classifier"

  mvn deploy:deploy-file $args >/dev/stderr

  echo $version
}

check_artifact() {
  local url=$1
  local artifact=$2
  local version=$3
  local src=$4

  jq -n "{
    source: {
      url: $(echo $url | jq -R .),
      artifact: $(echo $artifact | jq -R .)
    },
    version: {
      version: $(echo $version | jq -R .)
    }
  }" | $resource_dir/check "$src" | tee /dev/stderr
}

create_version_file() {
  local version=$1
  local src=$2

  mkdir $src/version
  echo "$version" > $src/version/number

  echo version/number
}

get_artifact() {
    local url=$1
    local artifact=$2
    local version=$3
    local src=$4

    jq -n "{
      source: {
        url: $(echo $url | jq -R .),
        artifact: $(echo $artifact | jq -R .)
      },
      version: {
        version: $(echo $version | jq -R .)
      }
    }" | $resource_dir/in "$src" | tee /dev/stderr
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
  local artifact=$groupId:$artifactId:$packaging

  # Mock the jar
  mkdir $src/build-output
  touch $src/build-output/$artifactId-$version.$packaging

  jq -n "{
    params: {
      file: $(echo $file | jq -R .),
      version_file: $(echo $version_file | jq -R .)
    },
    source: {
      url: $(echo $url | jq -R .),
      artifact: $(echo $artifact | jq -R .)
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
  local artifact=$groupId:$artifactId:$packaging

  # Mock the jar
  mkdir $src/build-output
  touch $src/build-output/$artifactId-$version.$packaging

  cat <<EOF | $resource_dir/out "$src" | tee /dev/stderr
  {
    "params": {
      "file": "$file",
      "version_file": "$version_file"
    },
    "source": {
      "url": "$url",
      "artifact": "$artifact",
      "username": "$username",
      "password": "$password",
      "repository_cert": "$repository_cert"
    }
  }
EOF
}

# deploy_with_pom_without_credentials() {
#
#   local url=$1
#   local pom=$2
#   local src=$3
#
#   local groupId=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='groupId']/text()" $pom)
#   local artifactId=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='artifactId']/text()" $pom)
#   local packaging=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='packaging']/text()" $pom)
#   local version=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='version']/text()" $pom)
#
#   local file=build-output/$artifactId-*.$packaging
#
#   local artifact=$groupId:$artifactId:$packaging
#
#   # Mock the jar
#   mkdir $src/build-output
#   touch $src/build-output/$artifactId-$version.$packaging
#
#   jq -n "{
#     params: {
#       file: $(echo $file | jq -R .),
#       pom: $(echo $pom | jq -R .)
#     },
#     source: {
#       url: $(echo $url | jq -R .),
#       artifact: $(echo $artifact | jq -R .)
#     }
#   }" | $resource_dir/out "$src" | tee /dev/stderr
# }

# deploy_with_pom_with_credentials() {
#
#   local url=$1
#   local pom=$2
#   local username=$3
#   local password=$4
#   local repository_cert=$(echo "$5" | awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}')
#   local src=$6
#
#   local groupId=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='groupId']/text()" $pom)
#   local artifactId=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='artifactId']/text()" $pom)
#   local packaging=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='packaging']/text()" $pom)
#   local version=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='version']/text()" $pom)
#
#   local artifact=$groupId:$artifactId:$packaging
#
#   local file=build-output/$artifactId-*.$packaging
#
#   # Mock the jar
#   mkdir $src/build-output
#   touch $src/build-output/$artifactId-$version.$packaging
#
#   cat <<EOF | $resource_dir/out "$src" | tee /dev/stderr
#   {
#     "params": {
#       "file": "$file",
#       "pom": "$pom"
#     },
#     "source": {
#       "url": "$url",
#       "artifact": "$artifact",
#       "username": "$username",
#       "password": "$password",
#       "repository_cert": "$repository_cert"
#     }
#   }
# EOF
# }
