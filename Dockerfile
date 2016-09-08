FROM openjdk:8-jdk-alpine

RUN apk add --no-cache curl tar bash jq libxml2-utils

ADD assets/ /opt/resource/
ADD test/ /opt/resource-tests/

# Run tests (also pre-seeds .m2/repository)
RUN /opt/resource-tests/all.sh
