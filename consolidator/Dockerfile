FROM openjdk:11
ARG consolidator_config_url
ARG ballerina_download_url=https://dist.ballerina.io/downloads/swan-lake-beta3/ballerina-linux-installer-x64-swan-lake-beta3.deb
ENV consolidator_config_file_url_env=${consolidator_config_url}
COPY ./target/bin/*.jar consolidator.jar
RUN wget -q --show-progress ${ballerina_download_url} -O ballerina-linux-installer-x64.deb
RUN dpkg -i ballerina-linux-installer-x64.deb
#TODO Link to be parameterized instead of hardcoding
CMD wget -q --show-progress "${consolidator_config_file_url_env}" -O Config.toml;\
    bal run ./consolidator.jar ;\
