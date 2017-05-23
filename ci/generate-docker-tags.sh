#!/bin/sh

set -e

version=$(cat version/version)

echo $version > task-output/tag-alpine
echo "$version-debian" > task-output/tag-debian
