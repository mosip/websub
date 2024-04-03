FROM openjdk:11
ARG SOURCE
ARG COMMIT_HASH
ARG COMMIT_ID
ARG BUILD_TIME
LABEL source=${SOURCE}
LABEL commit_hash=${COMMIT_HASH}
LABEL commit_id=${COMMIT_ID}
LABEL build_time=${BUILD_TIME}
ARG container_user=mosip
ARG container_user_group=mosip
ARG container_user_uid=1001
ARG container_user_gid=1001
ARG hub_config_url
ARG max_heap_size=2048m
ARG ballerina_download_url=https://dist.ballerina.io/downloads/2201.0.0/ballerina-2201.0.0-swan-lake-linux-x64.deb
ENV hub_config_file_url_env=${hub_config_url}
COPY ./target/bin/*.jar hub.jar
EXPOSE 9191

# Parameterized link
CMD wget -q --show-progress "${hub_config_file_url_env}" -O Config.toml && \
    java -jar -Xms256m -Xmx2048m ./hub.jar

WORKDIR /home/${container_user}
RUN wget -q --show-progress ${ballerina_download_url} -O ballerina-linux-installer-x64.deb \
    && dpkg -i ballerina-linux-installer-x64.deb \
    && rm ballerina-linux-installer-x64.deb \
    && chown -R ${container_user}:${container_user} /home/${container_user} \
    && usermod -u ${container_user_uid} ${container_user} \
    && groupmod -g ${container_user_gid} ${container_user}
USER ${container_user_uid}:${container_user_gid}
