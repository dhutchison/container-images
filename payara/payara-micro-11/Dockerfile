FROM amazoncorretto:11

# Default payara ports to expose
EXPOSE 8080
EXPOSE 8443

# Configure environment variables
ENV PAYARA_HOME=/opt/payara\
    CONFIG_ROOT_DIR=/opt/payara/configuration/domain\
    CONFIG_SCRIPTS_DIR=/opt/payara/configuration/scripts\
    DEPLOY_DIR=/opt/payara/deployments

# install packages to provide groupadd and wget
RUN yum install shadow-utils.x86_64 wget -y

# Create and set the Payara user and working directory owned by the new user
RUN groupadd payara && \
    useradd -N --home-dir ${PAYARA_HOME} -s /bin/bash -g payara payara && \
    echo payara:payara | chpasswd && \
    mkdir -p ${DEPLOY_DIR} && \
    mkdir -p ${CONFIG_SCRIPTS_DIR} && \
    mkdir -p "${CONFIG_ROOT_DIR}/config" && \
    chown -R payara:payara ${PAYARA_HOME}
USER payara
WORKDIR ${PAYARA_HOME}

# Copy in configuration files
COPY --chown=payara:payara postboot.txt "${CONFIG_SCRIPTS_DIR}/"
COPY --chown=payara:payara metrics.xml "${CONFIG_ROOT_DIR}/config/"

# Default command to run
# As this is the "Exec" form, variable substitution is not possible
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=90.0", "--add-opens=java.base/jdk.internal.loader=ALL-UNNAMED", "--add-opens=jdk.management/com.sun.management.internal=ALL-UNNAMED", "--add-exports=java.base/jdk.internal.ref=ALL-UNNAMED", "--add-opens=java.base/java.lang=ALL-UNNAMED", "--add-opens=java.base/java.nio=ALL-UNNAMED", "--add-opens=java.base/sun.nio.ch=ALL-UNNAMED", "--add-opens=java.management/sun.management=ALL-UNNAMED", "--add-opens=java.base/sun.net.www.protocol.jrt=ALL-UNNAMED", "-jar", "payara-micro.jar", "--autobindssl", "--sslport", "8443", "--disablephonehome", "--rootdir", "/opt/payara/configuration/domain", "--postbootcommandfile", "/opt/payara/configuration/scripts/postboot.txt", "--maxhttpthreads", "50"]

# Re-add
# "--postbootcommandfile", "${CONFIG_SCRIPTS_DIR}/postboot.txt"

# Want to tweak these default settings too
# --maxhttpthreads (10)
# --minhttpthreads (10)

CMD ["--deploymentDir", "/opt/payara/deployments"]

# Download specific
ARG PAYARA_VERSION="5.194"
ENV PAYARA_VERSION="$PAYARA_VERSION"
RUN wget --no-verbose -O ${PAYARA_HOME}/payara-micro.jar http://central.maven.org/maven2/fish/payara/extras/payara-micro/${PAYARA_VERSION}/payara-micro-${PAYARA_VERSION}.jar
