export TMPDIR=${TMPDIR:-/tmp}

# 1.0.0-20170328.031519-19
readonly UNIQUE_SNAPSHOT_PATTERN="\-[0-9]{8}\.[0-9]{6}-[0-9]{1,}"

is_snapshot() {
  local version=$1
  [[ "$version" = *-SNAPSHOT ]] || echo "$version" | grep -oEq "$UNIQUE_SNAPSHOT_PATTERN"
}

error_and_exit() {
  local message=$1
  printf '\e[91m[ERROR]\e[0m %s\n' "$message"
  exit 1
}

get_group_id() {
  echo $1 | cut -d ":" -f 1
}

get_artifact_id() {
  echo $1 | cut -d ":" -f 2
}

get_packaging() {
  echo $1 | cut -d ":" -f 3
}

get_classifier() {
  echo $1 | cut -d ":" -f 4
}
