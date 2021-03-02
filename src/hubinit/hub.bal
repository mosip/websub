import ballerina/config;
import ballerina/http;
import ballerina/log;
import ballerina/runtime;
import ballerina/websub;
import ballerinax/java.jdbc;
import mosip/filters as fil;
import mosip/repository;

import mosip/services;



jdbc:Client jdbcClient = new ({
        url: config:getAsString("mosip.hub.datasource-url", "jdbc:postgresql://localhost:9001/hub"),
        username: config:getAsString("mosip.hub.datasource-username"),
        password: config:getAsString("mosip.hub.datasource-password"),
        dbOptions: {useSSL: false}
    }
    );

repository:DeliveryReportPersistence deliveryReportPersistence = new repository:DeliveryReportPersistence(jdbcClient);
repository:MessagePersistenceImpl messagePersistenceImpl = new repository:MessagePersistenceImpl(jdbcClient);
repository:SubsOperations subsOperations = new repository:SubsOperations(jdbcClient);
services:HubServiceImpl hubServiceImpl = new services:HubServiceImpl(deliveryReportPersistence, messagePersistenceImpl, subsOperations);

http:RequestFilter requestFilter = new fil:RequestFilter(hubServiceImpl);
listener http:Listener hubListener = new http:Listener(config:getAsInt("mosip.hub.port"),
    config = {filters: [requestFilter]});

public function tapOnDeliveryImpl(string callback, string topic, websub:WebSubContent content) {
    hubServiceImpl.onSucessDelivery(callback, topic, content);
}

public function tapOnDeliveryFailureImpl(string callback, string topic, websub:WebSubContent content, http:Response|error response, websub:FailureReason reason) {
    hubServiceImpl.onFailedDelivery(callback, topic, content, response, reason);
}

public function main() {
    repository:RestartRepublishContentModel[] unSendMessages = hubServiceImpl.getUnSendMessages();

    websub:HubPersistenceStore hubpimpl = new repository:HubPersistenceImpl(jdbcClient);
    log:printInfo("Starting up the Ballerina Hub Service");

    websub:Hub webSubHub;
    var result = websub:startHub(hubListener, "/websub", "/hub",
        hubConfiguration = {
        remotePublish: {
            enabled: true
        },
        hubPersistenceStore: hubpimpl,
        clientConfig: {
            retryConfig: {
                count: config:getAsInt("mosip.hub.retry_count"),
                intervalInMillis: config:getAsInt("mosip.hub.retry_interval"),
                backOffFactor: config:getAsFloat("mosip.hub.retry_backoff_factor"),
                maxWaitIntervalInMillis: config:getAsInt("mosip.hub.retry_max_wait_interval")
            }
        },
        tapOnDelivery: tapOnDeliveryImpl,
        tapOnDeliveryFailure: tapOnDeliveryFailureImpl

    }
    );
    if (result is websub:Hub) {
        webSubHub = result;
        if (unSendMessages.length() > 0) {
            foreach var unSendMessage in unSendMessages {
                var publishResponse = webSubHub.publishUpdate(unSendMessage.topic, unSendMessage.message);
                if (publishResponse is error) {
                    log:printError("Error notifying hub: " +
                        <string>publishResponse.detail()?.message);
                } else {
                    log:printInfo("Update notification successful!");
                }
                runtime:sleep(2000);
            }
        }

    } else if (result is websub:HubStartedUpError) {
        webSubHub = result.startedUpHub;
    } else {
        log:printError("Hub start error:" + <string>result.detail()?.message);
        return;
    }
    while (true) {
        runtime:sleep(1);
    }
}
