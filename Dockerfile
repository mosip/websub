FROM ballerina/ballerina:1.2.13

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

# environment variable to pass number of retry attempts before giving up, at docker runtime
ENV hub_retry_count_env=${hub_retry_count}

# environment variable to pass retry interval in milliseconds, at docker runtime
ENV hub_retry_interval_env=${hub_retry_interval}

# environment variable to pass multiplier, which increases the retry interval exponentially, at docker runtime
ENV hub_retry_backoff_factor_env=${hub_retry_backoff_factor}

# environment variable to pass maximum time of the retry interval in milliseconds, at docker runtime
ENV hub_retry_max_wait_interval_env=${hub_retry_max_wait_interval}

COPY ./target/bin/*.jar hub.jar

EXPOSE 9091



CMD ballerina run ./hub.jar --mosip.hub.datasource-url="${hub_datasource_url_env}" --mosip.hub.datasource-username="${hub_datasource_username_env}" --mosip.hub.datasource-password="${hub_datasource_password_env}" --mosip.hub.retry_count="${hub_retry_count_env}" --mosip.hub.retry_interval="${hub_retry_interval_env}" --mosip.hub.retry_backoff_factor="${hub_retry_backoff_factor_env}" --mosip.hub.retry_max_wait_interval="${hub_retry_max_wait_interval_env}" --mosip.hub.port=9191 ;\