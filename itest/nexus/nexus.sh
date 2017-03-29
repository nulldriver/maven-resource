#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

imageName=nexus
export REPO_DOMAIN="$(docker-machine ip):8443"

url=https://$REPO_DOMAIN/

isRunning=$(docker ps | grep $imageName >/dev/null 2>&1 && echo true || echo false)
if [ $isRunning = "false" ]; then

  isCreated=$(docker ps -a | grep $imageName >/dev/null 2>&1 && echo true || echo false)
  if [ $isCreated = "true" ]; then
    docker start $imageName
  else

    if [ ! -f "$DIR/keystore.jks" ]; then
      keytool -genkey -noprompt \
        -keyalg RSA \
        -keysize 2048 \
        -validity 365 \
        -alias nexus \
        -dname "CN=$REPO_DOMAIN, OU=IT, O=Somewhere, L=Dallas, ST=TX, C=US" \
        -keystore $DIR/keystore.jks \
        -storepass changeit \
        -keypass changeit
    fi

    docker run -d \
      --name nexus \
      -p 8081:8081 \
      -p 8443:8443 \
      -v $DIR/keystore.jks:/nexus-data/keystore.jks \
      -e JKS_PASSWORD=changeit \
      clearent/nexus:3.2.0-01
  fi
else
  echo "$imageName is already running..."
fi

until $(curl --output /dev/null --silent --head --fail --insecure $url); do
    printf '.'
    sleep 5
done

echo "$imageName running at: $url"
