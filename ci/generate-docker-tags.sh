#!/bin/sh

set -e

version=$(cat version/version)

echo $version > generate-docker-tags-output/tag-alpine
echo "$version-debian" > generate-docker-tags-output/tag-debian
