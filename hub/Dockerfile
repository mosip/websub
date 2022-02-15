FROM openjdk:11
ARG hub_config_url
ARG ballerina_download_url=https://dist.ballerina.io/downloads/2201.0.0/ballerina-2201.0.0-swan-lake-linux-x64.deb
ENV hub_config_file_url_env=${hub_config_url}
COPY ./target/bin/*.jar hub.jar
EXPOSE 9191
RUN wget -q --show-progress ${ballerina_download_url} -O ballerina-linux-installer-x64.deb
RUN dpkg -i ballerina-linux-installer-x64.deb
#TODO Link to be parameterized instead of hardcoding
CMD wget -q --show-progress "${hub_config_file_url_env}" -O Config.toml;\
    bal run ./hub.jar ;\
