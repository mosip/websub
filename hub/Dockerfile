FROM openjdk:17
ARG SOURCE
ARG COMMIT_HASH
ARG COMMIT_ID
ARG BUILD_TIME
LABEL source=${SOURCE}
LABEL commit_hash=${COMMIT_HASH}
LABEL commit_id=${COMMIT_ID}
LABEL build_time=${BUILD_TIME}
ARG hub_config_url
ARG max_heap_size=2048m
ARG ballerina_download_url=https://dist.ballerina.io/downloads/2201.8.6/ballerina-2201.8.6-swan-lake-linux-x64.deb
ENV hub_config_file_url_env=${hub_config_url}
COPY ./target/bin/*.jar hub.jar
EXPOSE 9191
RUN apt update && apt install wget -y
RUN wget -q --show-progress ${ballerina_download_url} -O ballerina-linux-installer-x64.deb
RUN dpkg -i ballerina-linux-installer-x64.deb
#TODO Link to be parameterized instead of hardcoding
CMD wget -q --show-progress "${hub_config_file_url_env}" -O Config.toml;\
    java -jar -Xms256m -Xmx2048m ./hub.jar ;\
