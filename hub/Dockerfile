FROM openjdk:11
ENV hub_config_file_url_env=${hub_config_url}
COPY ./target/bin/*.jar hub.jar
EXPOSE 9191
RUN wget -q --show-progress https://dist.ballerina.io/downloads/swan-lake-beta2/ballerina-linux-installer-x64-swan-lake-beta2.deb -O ballerina-linux-installer-x64.deb
RUN dpkg -i ballerina-linux-installer-x64.deb
#TODO Link to be parameterized instead of hardcoding
CMD wget -q --show-progress "${hub_config_file_url_env}" -O Config.toml;\
    bal run ./hub.jar ;\