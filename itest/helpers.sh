#!/bin/bash

set -eu
set -o pipefail

export TMPDIR_ROOT=$(mktemp -d /tmp/mvn-tests.XXXXXX)

on_exit() {
  exitcode=$?
  if [ $exitcode != 0 ] ; then
    printf '\e[41;33;1mFailure encountered!\e[0m\n'
  fi
  rm -rf "$TMPDIR_ROOT"
}

trap on_exit EXIT

base_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
if [ -d "$base_dir/assets" ]; then
  resource_dir=$base_dir/assets
else
  resource_dir=/opt/resource
fi

run() {
  export TMPDIR=$(mktemp -d ${TMPDIR_ROOT}/mvn-tests.XXXXXX)

  # convert multiple args to single arg so printf doesn't output multiple lines
  printf 'running \e[33m%s\e[0m...\n' "$(echo "$@")"
  eval "$@" 2>&1 | sed -e 's/^/  /g'
  echo ""
}

assert_equals() {
  local expected=$1
  local actual=$2

  if [ "$expected" != "$actual" ]; then
    printf '\e[91mAssertion Failure:\e[0m\n'
    printf 'Expected :\e[91m%s\e[0m\n' "$expected"
    printf 'Actual   :\e[91m%s\e[0m\n' "$actual"
    return 1
  fi
}

assert_matches() {
  local actual=$1
  local pattern=$2

  if ! echo "$actual" | grep -oEq "$pattern"; then
    printf '\e[91mAssertion Failure:\e[0m\n'
    printf 'Expected :\e[91m(a value matching pattern "%s")\e[0m\n' "$pattern"
    printf 'Actual   :\e[91m%s\e[0m\n' "$actual"
    return 1
  fi
}

gen_artifact_id() {
  uuidgen
}

check_a_snapshot_and_return_the_unique_version() {

  local artifact=$1

  jq -n \
  --arg artifact "$artifact" \
  --arg url "$MVN_REPO_URL" \
  --arg username "$MVN_REPO_USERNAME" \
  --arg password "$MVN_REPO_PASSWORD" \
  '{
    source: {
      artifact: $artifact,
      url: $url,
      username: $username,
      password: $password
    }
  }' | "$resource_dir/check" | tee /dev/stderr
}

put_a_snapshot_and_return_the_unique_version() {

  local artifact=$1

  local job_dir=$(mktemp -d $TMPDIR/out-src.XXXXXX)

  mkdir -p "$job_dir/artifact"
  cp "$base_dir/test/fixtures/project/target/"project-*.jar "$job_dir/artifact/."

  mkdir -p "$job_dir/version"
  echo "1.0.0-SNAPSHOT" > "$job_dir/version/version"

  jq -n \
  --arg file "artifact/project-*.jar" \
  --arg version "version/version" \
  --arg artifact "$artifact" \
  --arg url "$MVN_REPO_URL" \
  --arg username "$MVN_REPO_USERNAME" \
  --arg password "$MVN_REPO_PASSWORD" \
  '{
    params: {
      file: $file,
      version_file: $version
    },
    source: {
      artifact: $artifact,
      url: $url,
      username: $username,
      password: $password
    }
  }' | "$resource_dir/out" "$job_dir" | tee /dev/stderr
}
