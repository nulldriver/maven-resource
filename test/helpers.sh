#!/bin/bash

set -eu
set -o pipefail

export TMPDIR_ROOT=$(mktemp -d /tmp/mvn-tests.XXXXXX)

on_exit() {
  exitcode=$?
  if [ $exitcode != 0 ] ; then
    printf '\e[41;33;1mFailure encountered!\e[0m\n'
  fi
  rm -rf $TMPDIR_ROOT
}

trap on_exit EXIT

base_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
if [ -d "$base_dir/assets" ]; then
  resource_dir=$base_dir/assets
else
  resource_dir=/opt/resource
fi

source $resource_dir/common.sh

run() {
  export TMPDIR=$(mktemp -d ${TMPDIR_ROOT}/mvn-tests.XXXXXX)

  # convert multiple args to single arg so printf doesn't output multiple lines
  printf "running \e[33m%s\e[0m...\n" "$(echo "$@")"
  eval "$@" 2>&1 | sed -e 's/^/  /g'
  echo ""
}

UNIQUE_ID=$(date '+%s')
increment_unique_id() {
  UNIQUE_ID=$((UNIQUE_ID + 1))
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
  local url=$1
  local artifact=$2
  local version=$3
  local src=$4

  local groupId=$(get_group_id $artifact)
  local artifactId=$(get_artifact_id $artifact)
  local packaging=$(get_packaging $artifact)
  local classifier=$(get_classifier $artifact)

  local file=$src/$(to_filename $artifact $version)
  echo "dummy jar (maven won't deploy a zero length file)" > $file

  local args="
    -Dfile=$file
    -Durl=$url
    -DgroupId=$(get_group_id $artifact)
    -DartifactId=$(get_artifact_id $artifact)
    -Dversion=$version
  "
  [ -n "$classifier" ] && args="$args -Dclassifier=$classifier"

  export MAVEN_BASEDIR=$resource_dir
  $resource_dir/mvnw deploy:deploy-file $args >/dev/stderr

  # cleanup dummy file
  rm $file

  echo $version
}

deploy_artifact_to_manager_with_pom() {

  local project=$1
  local version=$2
  local debug=$3

  local src=$(mktemp -d $TMPDIR/out-src.XXXXXX)

  cp -R $project $src/project

  pushd $src/project >/dev/null
  {
    ./mvnw versions:set -DnewVersion=$version
    ./mvnw clean package
    local groupId=$(printf 'GROUP_ID=${project.groupId}\n0\n' | ./mvnw help:evaluate | grep '^GROUP_ID' | cut -d = -f 2)
    local artifactId=$(printf 'ARTIFACT_ID=${project.artifactId}\n0\n' | ./mvnw help:evaluate | grep '^ARTIFACT_ID' | cut -d = -f 2)
    local packaging=$(printf 'PACKAGING=${project.packaging}\n0\n' | ./mvnw help:evaluate | grep '^PACKAGING' | cut -d = -f 2)
  } >/dev/stderr
  popd >/dev/null

  jq -n \
  --arg file "$src/project/target/project-$version.jar" \
  --arg pom_file "$src/project/pom.xml" \
  --arg url "$REPO_URL" \
  --arg snapshot_url "$REPO_SNAPSHOT_URL" \
  --arg artifact "$groupId:$artifactId:$packaging" \
  --arg username "$REPO_USERNAME" \
  --arg password "$REPO_PASSWORD" \
  --arg skip_cert_check "$REPO_SKIP_CERT_CHECK" \
  --arg repo_cert "$REPO_CERT" \
  --arg disable_redeploy "$REPO_DISABLE_REDEPLOY" \
  --arg debug "$debug" \
  '{
    params: {
      file: $file,
      pom_file: $pom_file
    },
    source: {
      url: $url,
      snapshot_url: $snapshot_url,
      artifact: $artifact,
      username: $username,
      password: $password,
      skip_cert_check: $skip_cert_check,
      repository_cert: $repo_cert,
      disable_redeploy: $disable_redeploy,
      debug: $debug
    }
  }' | $resource_dir/out "$src" | tee /dev/stderr
}

check_artifact() {
  local url=$1
  local artifact=$2
  local version=$3
  local src=$4

  jq -n \
  --arg url "$url" \
  --arg artifact "$artifact" \
  --arg version "$version" \
  '{
    source: {
      url: $url,
      artifact: $artifact
    },
    version: {
      version: $version
    }
  }' | $resource_dir/check "$src" | tee /dev/stderr
}

check_artifact_from_manager() {

  local version=$1
  local debug=$2

  local src=$(mktemp -d $TMPDIR/check-src.XXXXXX)

  jq -n \
  --arg version "$version" \
  --arg url "$REPO_URL" \
  --arg snapshot_url "$REPO_SNAPSHOT_URL" \
  --arg artifact 'com.example:project:jar' \
  --arg username "$REPO_USERNAME" \
  --arg password "$REPO_PASSWORD" \
  --arg repo_cert "$REPO_CERT" \
  --arg debug "$debug" \
  '{
    version: {
      version: $version
    },
    source: {
      url: $url,
      snapshot_url: $snapshot_url,
      artifact: $artifact,
      username: $username,
      password: $password,
      repository_cert: $repo_cert,
      debug: $debug
    }
  }' | $resource_dir/check "$src" | tee /dev/stderr
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

    jq -n \
    --arg url "$url" \
    --arg artifact "$artifact" \
    --arg version "$version" \
    '{
      source: {
        url: $url,
        artifact: $artifact
      },
      version: {
        version: $version
      }
    }' | $resource_dir/in "$src" | tee /dev/stderr
}

deploy_without_pom_without_credentials() {

  local url=$1
  local snapshot_url=${4:-''}
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

  # Mock the pom.xml
  local pom=build-output/pom.xml
  if [[ "$version" = *-SNAPSHOT ]]; then
    cp $base_dir/test/resources/pom-release.xml $src/$pom
  else
    cp $base_dir/test/resources/pom-snapshot.xml $src/$pom
  fi

  jq -n \
  --arg file "$file" \
  --arg pom "$pom" \
  --arg version_file "$version_file" \
  --arg url "$url" \
  --arg snapshot_url "$snapshot_url" \
  --arg artifact "$artifact" \
  '{
    params: {
      file: $file,
      pom_file: $pom,
      version_file: $version_file
    },
    source: {
      url: $url,
      snapshot_url: $snapshot_url,
      artifact: $artifact
    }
  }' | $resource_dir/out "$src" | tee /dev/stderr
}

deploy_without_pom_with_credentials() {

  local version=$1
  local username=$2
  local password=$3
  # local repository_cert=$(echo "$5" | awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}')
  local repository_cert=$4
  local src=$5
  local url=$6
  local snapshot_url=$7

  local version_file=$(create_version_file "$version" "$src")

  local groupId=org.some.group
  local artifactId=your-artifact
  local packaging=jar

  local file=build-output/$artifactId-*.$packaging
  local artifact=$groupId:$artifactId:$packaging

  # Mock the jar
  mkdir $src/build-output
  touch $src/build-output/$artifactId-$version.$packaging

  jq -n \
  --arg file "$file" \
  --arg version_file "$version_file" \
  --arg url "$url" \
  --arg snapshot_url "$snapshot_url" \
  --arg artifact "$artifact" \
  --arg username "$username" \
  --arg password "$password" \
  --arg repository_cert "$repository_cert" \
  '{
    params: {
      file: $file,
      version_file: $version_file
    },
    source: {
      url: $url,
      snapshot_url: $snapshot_url,
      artifact: $artifact,
      username: $username,
      password: $password,
      repository_cert: $repository_cert
    }
  }' | $resource_dir/out "$src" | tee /dev/stderr
}
