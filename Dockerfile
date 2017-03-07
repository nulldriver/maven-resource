FROM openjdk:8-jdk

RUN apt-get update && apt-get install -y \
    curl tar bash jq libxml2-utils \
  && rm -rf /var/lib/apt/lists/*

ADD assets/ /opt/resource/
ADD test/ /opt/resource-tests/
ADD itest/ /opt/resource-itests/

# Run tests (also pre-seeds .m2/repository)
RUN /opt/resource-tests/all.sh
