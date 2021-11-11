FROM adoptopenjdk/openjdk8:latest

RUN apt-get update \
    && apt-get install -y curl tar bash jq xqilla \
    && rm -rf /var/lib/apt/lists/*

ADD assets/ /opt/resource/
ADD test/ /opt/resource/test/
ADD itest/ /opt/resource/itest/

# Run tests (also pre-seeds .m2/repository)
RUN /opt/resource/test/all.sh
