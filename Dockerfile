FROM openjdk:8
ENV hub_config_file_url_env=${hub_config_url}
COPY ./target/bin/*.jar hub.jar
EXPOSE 9191
RUN wget -q --show-progress https://dist.ballerina.io/downloads/1.2.13/ballerina-linux-installer-x64-1.2.13.deb
RUN dpkg -i ballerina-linux-installer-x64-1.2.13.deb
#TODO Link to be parameterized instead of hardcoding
CMD wget -q --show-progress "${hub_config_file_url_env}" ;\
    ballerina run ./hub.jar --b7a.config.file=websub.conf ;\