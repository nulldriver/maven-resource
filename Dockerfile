FROM openjdk:8-jdk-alpine

RUN apk add --no-cache wget curl tar bash jq libxml2-utils xmlstarlet

ADD assets/ /opt/resource/
ADD test/ /opt/resource-tests/

ARG MAVEN_VERSION=3.3.9

# Download Maven and verify the md5 hash
RUN cd /tmp \
  && wget http://mirrors.ibiblio.org/apache/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz \
  && wget https://www.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz.md5 \
  && echo "  apache-maven-$MAVEN_VERSION-bin.tar.gz" >> apache-maven-$MAVEN_VERSION-bin.tar.gz.md5 \
  && md5sum -c apache-maven-$MAVEN_VERSION-bin.tar.gz.md5

# Install Maven
RUN cd /tmp \
  && mkdir -p /usr/share/maven \
  && tar -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz -C /usr/share/maven --strip-components=1 \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

# Cleanup Download
RUN cd /tmp \
  && rm apache-maven-$MAVEN_VERSION-bin.tar.gz apache-maven-$MAVEN_VERSION-bin.tar.gz.md5

# Run tests (also pre-seeds .m2/repository)
RUN /opt/resource-tests/test-out.sh
