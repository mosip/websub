// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerinax/kafka;
import ballerina/websubhub;
import ballerina/lang.value;
import ballerina/log;
import consolidatorService.config;
import consolidatorService.util;
import consolidatorService.connections as conn;
import consolidatorService.persistence as persist;
import ballerina/http;
import consolidatorService.health_check as healthcheck;
import consolidatorService.kafka_health_check as kafkahealthcheck;
import ballerina/jballerina.java;

http:Service healthCheckService = service object {

    resource function get .() returns http:Ok|http:ServiceUnavailable {
        //diskspace
        string diskSpaceStatus = "DOWN";
        handle handleStr = java:fromString(config:CURRENT_WORKING_DIR);
        handle fileObj = newFile(java:fromString(getCurrent(handleStr).toString()));
        int usableSpace = getUsableSpace(fileObj);
        int totalSpace = getTotalSpace(fileObj);
        int threshold = config:DISK_SPACE_THRESHOLD;
        healthcheck:DiskSpaceMetaData diskSpaceMetaData = {free: usableSpace, total: totalSpace, threshold: threshold};
        if (usableSpace >= threshold) {
            diskSpaceStatus = "UP";
        }
        healthcheck:HealthCheckResp diskSpace = {status: diskSpaceStatus, details: {diskSpaceMetaData}};

        //kafka
        string kafkaStatus = "DOWN";
       handle|error? producerResult = kafkahealthcheck:describeTopicKafka(config:CONSOLIDATED_WEBSUB_SUBSCRIBERS_TOPIC);
        if (producerResult is handle) {
            kafkaStatus = "UP";
        }
        healthcheck:HealthCheckResp kafkaHealth = {status: kafkaStatus, details: {}};
        //add to main map
        map<healthcheck:HealthCheckResp> details = {
            "diskSpace": diskSpace,
            "kafka": kafkaHealth
        };

        string resultStatus = "DOWN";
        if(diskSpaceStatus == "UP" && kafkaStatus == "UP"){
            resultStatus = "UP";
            healthcheck:HealthCheckResp healthCheckResp = {status: resultStatus, details: {details}};
            http:Ok res = {body: healthCheckResp};
            return res;
        }

        //main object
        healthcheck:HealthCheckResp healthCheckResp = {status: resultStatus, details: {details}};
        http:ServiceUnavailable res = {body: healthCheckResp};
        return res;
    }
};

function newFile(handle c) returns handle = @java:Constructor {
    'class: "java.io.File",
    paramTypes: ["java.lang.String"]
} external;

function getCurrent(handle prop) returns handle = @java:Method {
    name: "getProperty",
    'class: "java.lang.System"
} external;

function getUsableSpace(handle fileObj) returns int = @java:Method {
    'class: "java.io.File"
} external;

isolated function getTotalSpace(handle fileObj) returns int = @java:Method {
    'class: "java.io.File"
} external;

isolated function startConsolidator() returns error? {
    do {
        while true {
            kafka:BytesConsumerRecord[] records = check conn:websubEventConsumer->poll(config:POLLING_INTERVAL);
            foreach kafka:BytesConsumerRecord currentRecord in records {
                string lastPersistedData = check string:fromBytes(currentRecord.value);
                log:printInfo("websub event received in consolidator",payload=lastPersistedData);
                error? result = processPersistedData(lastPersistedData);
                if result is error {
                    log:printError("Error occurred while processing received event ", 'error = result);
                }
            }
        }
    } on fail var e {
        _ = check conn:websubEventConsumer->close(config:GRACEFUL_CLOSE_PERIOD);
        return e;
    }
}

isolated function processPersistedData(string persistedData) returns error? {
    json payload = check value:fromJsonString(persistedData);
    string hubMode = check payload.hubMode;
    match hubMode {
        "register" => {
            check processTopicRegistration(payload);
        }
        "deregister" => {
            check processTopicDeregistration(payload);
        }
        "subscribe" => {
            check processSubscription(payload);
        }
        "unsubscribe" => {
            check processUnsubscription(payload);
        }
        _ => {
            return error(string `Error occurred while deserializing subscriber events with invalid hubMode [${hubMode}]`);
        }
    }
}

isolated function processTopicRegistration(json payload) returns error? {
    websubhub:TopicRegistration registration = check value:cloneWithType(payload);
    string topicName = util:sanitizeTopicName(registration.topic);
    lock {
        // add the topic if topic-registration event received
        registeredTopicsCache[topicName] = registration.cloneReadOnly();
        _ = check persist:persistTopicRegistrations(registeredTopicsCache);
    }
}

isolated function processTopicDeregistration(json payload) returns error? {
    websubhub:TopicDeregistration deregistration = check value:cloneWithType(payload);
    string topicName = util:sanitizeTopicName(deregistration.topic);
    lock {
        // remove the topic if topic-deregistration event received
        _ = registeredTopicsCache.removeIfHasKey(topicName);
        _ = check persist:persistTopicRegistrations(registeredTopicsCache);
    }
}

isolated function processSubscription(json payload) returns error? {
    websubhub:VerifiedSubscription subscription = check payload.cloneWithType(websubhub:VerifiedSubscription);
    string subscriberID = util:generateSubscriberId(subscription.hubTopic, subscription.hubCallback);
    lock {
        // add the subscriber if subscription event received
         if !subscribersCache.hasKey(subscriberID) {
            subscribersCache[subscriberID] = subscription.cloneReadOnly();
        }
        _ = check persist:persistSubscriptions(subscribersCache);
    }
}

isolated function processUnsubscription(json payload) returns error? {
    websubhub:VerifiedUnsubscription unsubscription = check payload.cloneWithType(websubhub:VerifiedUnsubscription);
    string subscriberID = util:generateSubscriberId(unsubscription.hubTopic, unsubscription.hubCallback);
    lock {
        // remove the subscriber if the unsubscription event received
        _ = subscribersCache.removeIfHasKey(subscriberID);
        _ = check persist:persistSubscriptions(subscribersCache);
    }
}
