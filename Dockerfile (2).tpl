# A Java 8 runtime example
# The official Red Hat registry and the base image
FROM techrepo:443/redhat-remote/ubi8/openjdk-11
USER root

# Directory for application
RUN mkdir -p /app
RUN mkdir -p /opt/appdynamics/

# import kafka certificates
COPY kafka.truststore.jks /app/cacerts/
COPY kafka.truststoreprod.jks /app/cacerts/
COPY INGBANKCA.cer  /app/cacerts/INGBANKCA.cer
RUN keytool -import -alias ingbankcatest -file /app/cacerts/INGBANKCA.cer  -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit -noprompt -trustcacerts

COPY javaagent.zip /opt/appdynamics/
RUN unzip /opt/appdynamics/javaagent.zip -d /opt/appdynamics/
RUN chmod 777 -R /opt/appdynamics/

# Copy the application to the working directory
COPY ${packageName} /app/${packageName}
RUN curl -k https://techrepo:443/artifactory/APIs-dev-local/run-java-sh-1.3.8-sh.sh -o /app/run-java.sh && \
    chown 1001 /app && \
    chmod 540 /app/run-java.sh && \
    chmod "g+rwX" /app && \
    chmod 777 /tmp

USER 1001

ENV JAVA_OPTIONS="-Dstargate.core.application.tnsPathKey=oracle.net.tns_admin -Dstargate.core.application.tnsPathValue=${configPath}/oracle -Dspring.config.location=${configPath}/ -Dstargate.property.home=file:${configPath} -Dstargate.connection.application.tnsPathKey=oracle.net.tns_admin -Dstargate.property.profilesuffix=- -DatomikosTXName=corporatelendinggds-internal -Dstargate.property.profilesuffix=- -Dstargate.connection.application.tnsPathValue=${configPath}/oracle -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/java/dump.bin -Xlog:gc*:/app/gc_log.log -Xms2G -Xmx2G -XX:MaxGCPauseMillis=20 -XX:ParallelGCThreads=14 -XX:ConcGCThreads=4 -XX:InitiatingHeapOccupancyPercent=90 -XX:+UseStringDeduplication -XX:InitialCodeCacheSize=32m -XX:ReservedCodeCacheSize=64m -javaagent:/opt/appdynamics/javaagent/javaagent.jar -Dappdynamics.agent.applicationName=TPCLGDS -Dappdynamics.agent.tierName=internalapifeature -Dappdynamics.agent.nodeName=test_app -Dappdynamics.agent.node.use.as.ephemeral=true"

ENV JAVA_MAX_MEM_RATIO="65"

# Finally, run the application
ENTRYPOINT ["/app/run-java.sh"]