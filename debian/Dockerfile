FROM openjdk:8u151-jdk

RUN apt-get update && apt-get -y install jq libxml2-utils \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# https://github.com/concourse/concourse/issues/2042
RUN unlink  $JAVA_HOME/jre/lib/security/cacerts && \
    cp /etc/ssl/certs/java/cacerts $JAVA_HOME/jre/lib/security/cacerts

ADD assets/ /opt/resource/
ADD test/ /opt/resource/test/
ADD itest/ /opt/resource/itest/

# Run tests (also pre-seeds .m2/repository)
RUN /opt/resource/test/all.sh
