FROM ballerina/ballerina:1.2.8

# can be passed during Docker build as build time environment for spring profiles active 
ARG hub_datasource_url

# can be passed during Docker build as build time environment for config server URL 
ARG hub_datasource_username

# can be passed during Docker build as build time environment for glowroot 
ARG hub_datasource_password

# environment variable to pass active profile such as DEV, QA etc at docker runtime
ENV hub_datasource_url_env=${hub_datasource_url}

# environment variable to pass github branch to pickup configuration from, at docker runtime
ENV hub_datasource_username_env=${hub_datasource_username}

# environment variable to pass spring configuration url, at docker runtime
ENV hub_datasource_password_env=${hub_datasource_password}



ADD ./target/bin/*.jar /target/bin/
RUN find /target/bin -name '*.jar' -executable -type f "-print0" | xargs "-0" cp -t / \
    && rm -rf /target/bin \
    && mv *.jar hub.jar 

EXPOSE 9091



CMD ["ballerina","run",".\hub.jar","--mosip.hub.datasource-url=${hub_datasource_url_env}","--mosip.hub.datasource-username=${hub_datasource_username_env}"," --mosip.hub.datasource-password=${hub_datasource_password_env}","--mosip.hub.port=9191"]
