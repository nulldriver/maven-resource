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
