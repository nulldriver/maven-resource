FROM openjdk:8u131-jdk-alpine

RUN apk add --no-cache curl tar bash jq libxml2-utils

ADD assets/ /opt/resource/
ADD test/ /opt/resource/test/
ADD itest/ /opt/resource/itest/

# Run tests (also pre-seeds .m2/repository)
RUN /opt/resource/test/all.sh
