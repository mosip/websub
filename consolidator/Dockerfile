FROM openjdk:11

ARG consolidator_config_url
ARG max_heap_size=2048m
ARG min_heap_size=256m
ARG ballerina_download_url=https://dist.ballerina.io/downloads/2201.0.0/ballerina-2201.0.0-swan-lake-linux-x64.deb

# can be passed during Docker build as build time environment variable for mosip user level change.
ARG container_user=mosip
ARG container_user_group=mosip
ARG container_user_uid=1001
ARG container_user_gid=1001

# can be passed during Docker build as build time environment for label related addition to docker.
ARG SOURCE
ARG COMMIT_HASH
ARG COMMIT_ID
ARG BUILD_TIME

ENV consolidator_config_file_url_env=${consolidator_config_url}
ENV max_heap_size=${max_heap_size}
ENV min_heap_size=${min_heap_size}

# can be passed during Docker build as build time environment for label.
LABEL source=${SOURCE}
LABEL commit_hash=${COMMIT_HASH}
LABEL commit_id=${COMMIT_ID}
LABEL build_time=${BUILD_TIME}

WORKDIR /home/${container_user}

COPY ./target/bin/*.jar consolidator.jar
EXPOSE 9192
RUN groupadd -r -g ${container_user_gid} ${container_user_group} \
&&  useradd -r -u ${container_user_uid} -g ${container_user_group} ${container_user} \
&& wget -q --show-progress ${ballerina_download_url} -O ballerina-linux-installer-x64.deb \
&& dpkg -i ballerina-linux-installer-x64.deb \
&& chown -R ${container_user}:${container_user} /home/${container_user}
#TODO Link to be parameterized instead of hardcoding
USER ${container_user_uid}:${container_user_gid}
CMD wget -q --show-progress "${consolidator_config_file_url_env}" -O Config.toml;\
     java -jar -Xms${min_heap_size} -Xmx${max_heap_size} ./consolidator.jar ;
