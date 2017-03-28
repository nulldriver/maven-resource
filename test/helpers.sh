#!/bin/bash

set -e -u

set -o pipefail

export TMPDIR_ROOT=$(mktemp -d /tmp/mvn-tests.XXXXXX)
trap "rm -rf $TMPDIR_ROOT" EXIT

test_dir=$(dirname $0)

if [ -d /opt/resource ]; then
  export resource_dir=/opt/resource
else
  export resource_dir=$(cd $(dirname $0)/../assets && pwd)
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

  local src=$(mktemp -d $TMPDIR/out-src.XXXXXX)

  cp -R $project $src/project

  jq -n \
  --arg file $src/project/target/project-$version.jar \
  --arg pom_file $src/project/pom.xml \
  --arg url $REPO_URL \
  --arg snapshot_url $REPO_SNAPSHOT_URL \
  --arg artifact 'com.example:project:jar' \
  --arg username $REPO_USERNAME \
  --arg password $REPO_PASSWORD \
  --arg repo_cert "$REPO_CERT" \
  --arg disable_redeploy "true" \
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
      disable_redeploy: $disable_redeploy,
      repository_cert: $repo_cert
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

  local src=$(mktemp -d $TMPDIR/check-src.XXXXXX)

  jq -n \
  --arg version $version \
  --arg url $REPO_URL \
  --arg snapshot_url $REPO_SNAPSHOT_URL \
  --arg artifact 'com.example:project:jar' \
  --arg username $REPO_USERNAME \
  --arg password $REPO_PASSWORD \
  --arg repo_cert "$REPO_CERT" \
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
      repository_cert: $repo_cert
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
    cp $test_dir/resources/pom-release.xml $src/$pom
  else
    cp $test_dir/resources/pom-snapshot.xml $src/$pom
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
