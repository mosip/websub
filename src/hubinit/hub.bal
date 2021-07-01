import ballerina/config;
import ballerina/http;
import ballerina/log;
import ballerina/runtime;
import ballerina/task;
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
http:RequestFilter authFilter = new fil:AuthFilter();

listener http:Listener hubListener = new http:Listener(config:getAsInt("mosip.hub.port"),
    config = {filters: [authFilter, requestFilter]});

public function tapOnDeliveryImpl(string callback, string topic, websub:WebSubContent content) {
    hubServiceImpl.onSucessDelivery(callback, topic, content);
}

public function tapOnDeliveryFailureImpl(string callback, string topic, websub:WebSubContent content, http:Response|error response, websub:FailureReason reason) {
    hubServiceImpl.onFailedDelivery(callback, topic, content, response, reason);
}


public function main() {
    repository:RestartRepublishContentModel[] unsentMessages = hubServiceImpl.getUnsentMessages(config:getAsString("mosip.hub.restart_republish_time_offset"));
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
                maxWaitIntervalInMillis: config:getAsInt("mosip.hub.retry_max_wait_interval"),
                statusCodes: [404, 408, 502, 503, 504]
            }
        },
        tapOnDelivery: tapOnDeliveryImpl,
        tapOnDeliveryFailure: tapOnDeliveryFailureImpl

    }
    );
    if (result is websub:Hub) {

        webSubHub = result;
        if (config:getAsBoolean("mosip.hub.republish_enable", false)) {
            task:AppointmentData appointmentData = {
                seconds: config:getAsString("mosip.hub.republish-job-seconds"),
                minutes: config:getAsString("mosip.hub.republish-job-minutes"),
                hours: config:getAsString("mosip.hub.republish-job-hours"),
                daysOfMonth: config:getAsString("mosip.hub.republish-job-days-of-month"),
                months: config:getAsString("mosip.hub.republish-job-months"),
                daysOfWeek: config:getAsString("mosip.hub.republish-job-days-of-week"),
                year: config:getAsString("mosip.hub.republish-job-year")
            };

            task:Scheduler appointment = new ({appointmentDetails: appointmentData});
            RepublishJob republishJob = new RepublishJob();
            var attachResult = appointment.attach(republishJob.getRepublishservice(), hubServiceImpl, webSubHub);
            if (attachResult is error) {
                log:printError("Error attaching the service.");     
            }

            var startResult = appointment.start();
            if (startResult is error) {
                log:printError("Starting the task is failed.");
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
