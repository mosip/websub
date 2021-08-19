FROM openjdk:11
ENV consolidator_config_file_url_env=${consolidator_config_url}
COPY ./target/bin/*.jar consolidator.jar
EXPOSE 9192
RUN wget -q --show-progress https://dist.ballerina.io/downloads/swan-lake-beta2/ballerina-linux-installer-x64-swan-lake-beta2.deb -O ballerina-linux-installer-x64.deb
RUN dpkg -i ballerina-linux-installer-x64.deb
#TODO Link to be parameterized instead of hardcoding
CMD wget -q --show-progress "${consolidator_config_file_url_env}" -O Config.toml;\
    ballerina run ./consolidator.jar --b7a.config.file=Config.toml ;\