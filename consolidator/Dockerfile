FROM openjdk:11

ARG SOURCE
ARG COMMIT_HASH
ARG COMMIT_ID
ARG BUILD_TIME
ARG container_user=mosip
ARG container_user_group=mosip
ARG container_user_uid=1001
ARG container_user_gid=1001
LABEL source=${SOURCE}
LABEL commit_hash=${COMMIT_HASH}
LABEL commit_id=${COMMIT_ID}
LABEL build_time=${BUILD_TIME}
ARG consolidator_config_url
ARG max_heap_size=2048m
ARG ballerina_download_url=https://dist.ballerina.io/downloads/2201.0.0/ballerina-2201.0.0-swan-lake-linux-x64.deb
ENV consolidator_config_file_url_env=${consolidator_config_url}

# Create a user and group with specified UID and GID
RUN groupadd -r -g ${container_user_gid} ${container_user_group} && \
    useradd -r -u ${container_user_uid} -g ${container_user_group} ${container_user}

WORKDIR /home/${container_user}

COPY ./target/bin/*.jar consolidator.jar
EXPOSE 9192
RUN wget -q --show-progress ${ballerina_download_url} -O ballerina-linux-installer-x64.deb \
&& dpkg -i ballerina-linux-installer-x64.deb \
&& chown -R ${container_user}:${container_user} /home/${container_user}
#TODO Link to be parameterized instead of hardcoding
USER ${container_user_uid}:${container_user_gid}
CMD wget -q --show-progress "${consolidator_config_file_url_env}" -O Config.toml;\
     java -jar -Xms256m -Xmx${max_heap_size} ./consolidator.jar ;
