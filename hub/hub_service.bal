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

import ballerina/websubhub;
import ballerina/log;
import ballerina/http;
import kafkaHub.security;
import kafkaHub.persistence as persist;
import kafkaHub.config;
import kafkaHub.util;
import kafkaHub.healthcheck;
import ballerina/jballerina.java;
import kafkaHub.connections as conn;
import ballerinax/kafka;

http:Service healthCheckService = service object {

    resource function get .() returns healthcheck:HealthCheckResp {
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

        //consolidator
        string consolidatorStatus = "DOWN";
        http:Client|http:ClientError clientEndpoint =  new (config:CONSOLIDATOR_BASE_URL);
        if(clientEndpoint is http:ClientError){
         log:printError(clientEndpoint.message());
        }else{
        healthcheck:HealthCheckResp|error consolidatorHealth =  clientEndpoint -> get(config:CONSOLIDATOR_HEALTH_ENDPOINT);
        if(consolidatorHealth is healthcheck:HealthCheckResp){
         consolidatorStatus = consolidatorHealth.status;
        }
        }
        healthcheck:HealthCheckResp consolidatorSHealth = {status: consolidatorStatus, details: {}};
        //add to main map
        map<healthcheck:HealthCheckResp> details = {
            "diskSpace": diskSpace,
            "consolidator": consolidatorSHealth
        };
        string resultStatus = "DOWN";
        if(diskSpaceStatus == "UP" && consolidatorStatus == "UP"){
            resultStatus = "UP";
        }
        healthcheck:HealthCheckResp healthCheckResp = {status: resultStatus, details: {details}};
        return healthCheckResp;
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

websubhub:Service hubService = @websubhub:ServiceConfig { 
    webHookConfig: {
        retryConfig: {
            interval: config:INTENT_VERIFICATION_RETRY_INTERVAL,
            count: config:INTENT_VERIFICATION_COUNT,
            backOffFactor: config:INTENT_VERIFICATION_BACKOFF_FACTOR,
            maxWaitInterval: config:INTENT_VERIFICATION_MAX_INTERVAL
        }
    }
}
service object {

    # Registers a `topic` in the hub.
    #
    # + message - Details related to the topic-registration
    # + headers - `http:Headers` of the original `http:Request`
    # + return - `websubhub:TopicRegistrationSuccess` if topic registration is successful, `websubhub:TopicRegistrationError`
    # if topic registration failed or `error` if there is any unexpected error
    isolated remote function onRegisterTopic(websubhub:TopicRegistration message, http:Headers headers)
                                returns websubhub:TopicRegistrationSuccess|websubhub:TopicRegistrationError|error {
        if config:SECURITY_ON {
            check security:authorizePublisher(headers, message.topic);
        }
        check self.registerTopic(message);
        return websubhub:TOPIC_REGISTRATION_SUCCESS;
    }

    isolated function registerTopic(websubhub:TopicRegistration message) returns websubhub:TopicRegistrationError? {
        string topicName = util:sanitizeTopicName(message.topic);
        lock {
            if registeredTopicsCache.hasKey(topicName) {
                log:printError("Topic has already registered with the Hub", topic = topicName);
                return error websubhub:TopicRegistrationError("Topic has already registered with the Hub");
            }
            log:printDebug("Registering topic", topic = topicName);
            error? persistingResult = persist:addRegsiteredTopic(message.cloneReadOnly());
            if persistingResult is error {
                log:printError("Error occurred while persisting the topic-registration ", topic = topicName, err = persistingResult.message());
            } else {
                log:printInfo("Topic registered", topic = topicName);
            }
        }
    }

    # Deregisters a `topic` in the hub.
    #
    # + message - Details related to the topic-deregistration
    # + headers - `http:Headers` of the original `http:Request`
    # + return - `websubhub:TopicDeregistrationSuccess` if topic deregistration is successful, `websubhub:TopicDeregistrationError`
    # if topic deregistration failed or `error` if there is any unexpected error
    isolated remote function onDeregisterTopic(websubhub:TopicDeregistration message, http:Headers headers)
                        returns websubhub:TopicDeregistrationSuccess|websubhub:TopicDeregistrationError|error {
        if config:SECURITY_ON {
            check security:authorizePublisher(headers, message.topic);
        }
        check self.deregisterTopic(message);
        return websubhub:TOPIC_DEREGISTRATION_SUCCESS;
    }

    isolated function deregisterTopic(websubhub:TopicRegistration message) returns websubhub:TopicDeregistrationError? {
        string topicName = util:sanitizeTopicName(message.topic);
        lock {
            if !registeredTopicsCache.hasKey(topicName) {
                return error websubhub:TopicDeregistrationError("Topic has not been registered in the Hub");
            }
            log:printInfo("Running topic de-registration", payload = message);
            error? persistingResult = persist:removeRegsiteredTopic(message.cloneReadOnly());
            if persistingResult is error {
                log:printError("Error occurred while persisting the topic-deregistration ", err = persistingResult.message());
            }
        }
    }

    # Subscribes a `subscriber` to the hub.
    #
    # + message - Details of the subscription
    # + headers - `http:Headers` of the original `http:Request`
    # + return - `websubhub:SubscriptionAccepted` if subscription is accepted from the hub, `websubhub:BadSubscriptionError`
    # if subscription is denied from the hub or `error` if there is any unexpected error
    isolated remote function onSubscription(websubhub:Subscription message, http:Headers headers)
                returns websubhub:SubscriptionAccepted|websubhub:BadSubscriptionError|error {
        if config:SECURITY_ON {
            check security:authorizeSubscriber(headers, message.hubTopic);
        }
        log:printInfo("Subscription request received", payload = message);
        return websubhub:SUBSCRIPTION_ACCEPTED;
    }

    # Validates a incomming subscription request.
    #
    # + message - Details of the subscription
    # + return - `websubhub:SubscriptionDeniedError` if the subscription is denied by the hub or else `()`
    isolated remote function onSubscriptionValidation(websubhub:Subscription message)
                returns websubhub:SubscriptionDeniedError? {
        log:printDebug("Validating before sending intent verification", payload = message);
        string topicName = util:sanitizeTopicName(message.hubTopic);
        error? topicRegistrationFailed = self.createTopicIFNotExist(topicName, message.hubCallback);
        if (topicRegistrationFailed is error) {
            return error websubhub:SubscriptionDeniedError(topicRegistrationFailed.message());
        }
        string subscriberId = util:generateSubscriberId(message.hubTopic, message.hubCallback);
        boolean subscriberAvailable = false;
        lock {
            subscriberAvailable = subscribersCache.hasKey(subscriberId);
        }
        if subscriberAvailable {
            log:printError("Subscriber has already registered with the Hub", topic = topicName, callback = message.hubCallback);
            return error websubhub:SubscriptionDeniedError("Subscriber has already registered with the Hub");
        } else {
            log:printInfo("Validation done before sending intent verification", payload = message);
        }
    }

    # Processes a verified subscription request.
    #
    # + message - Details of the subscription
    # + return - `error` if there is any unexpected error or else `()`
    isolated remote function onSubscriptionIntentVerified(websubhub:VerifiedSubscription message) returns error? {
        log:printDebug("Subscription Intent verfication done", payload = message);
         string consumerGroup = util:generateGroupName(message.hubTopic, message.hubCallback);
        message["consumerGroup"] = consumerGroup;
        error? persistingResult = persist:addSubscription(message.cloneReadOnly());
        if persistingResult is error {
            log:printError("Error occurred while persisting the subscription ", err = persistingResult.message());
        }
        log:printInfo("Subscription Intent verfication done and stored to kafka", payload = message);
    }

    # Unsubscribes a `subscriber` from the hub.
    #
    # + message - Details of the unsubscription
    # + headers - `http:Headers` of the original `http:Request`
    # + return - `websubhub:UnsubscriptionAccepted` if unsubscription is accepted from the hub, `websubhub:BadUnsubscriptionError`
    # if unsubscription is denied from the hub or `error` if there is any unexpected error
    isolated remote function onUnsubscription(websubhub:Unsubscription message, http:Headers headers)
                returns websubhub:UnsubscriptionAccepted|websubhub:BadUnsubscriptionError|error {
        if config:SECURITY_ON {
            check security:authorizeSubscriber(headers, message.hubTopic);
        }
        log:printInfo("Unsubscription request received", payload = message);
        return websubhub:UNSUBSCRIPTION_ACCEPTED;
    }

    # Validates a incomming unsubscription request.
    #
    # + message - Details of the unsubscription
    # + return - `websubhub:UnsubscriptionDeniedError` if the unsubscription is denied by the hub or else `()`
    isolated remote function onUnsubscriptionValidation(websubhub:Unsubscription message)
                returns websubhub:UnsubscriptionDeniedError? {
        string topicName = util:sanitizeTopicName(message.hubTopic);
        boolean topicAvailable = false;
        boolean subscriberAvailable = false;
        lock {
            topicAvailable = registeredTopicsCache.hasKey(topicName);
        }
        if !topicAvailable {
            return error websubhub:UnsubscriptionDeniedError("Topic [" + message.hubTopic + "] is not registered with the Hub");
        } else {
           string subscriberId = util:generateSubscriberId(message.hubTopic, message.hubCallback);
            lock {
               subscriberAvailable = subscribersCache.hasKey(subscriberId);
            }
            if !subscriberAvailable {
                return error websubhub:UnsubscriptionDeniedError("Could not find a valid subscriber for Topic ["
                                + message.hubTopic + "] and Callback [" + message.hubCallback + "]");
            }
        }
        log:printInfo("Validation done a incomming Unsubscription request", payload = message);
    }

    # Processes a verified unsubscription request.
    #
    # + message - Details of the unsubscription
    isolated remote function onUnsubscriptionIntentVerified(websubhub:VerifiedUnsubscription message) {
        log:printInfo("Proessing a Intent verfied Unsubscription done for request", payload = message);
        var persistingResult = persist:removeSubscription(message.cloneReadOnly());
        if (persistingResult is error) {
            log:printError("Error occurred while persisting the unsubscription ", err = persistingResult.message());
        } 
    }

    # Publishes content to the hub.
    #
    # + message - Details of the published content
    # + headers - `http:Headers` of the original `http:Request`
    # + return - `websubhub:Acknowledgement` if publish content is successful, `websubhub:UpdateMessageError`
    # if publish content failed or `error` if there is any unexpected error
    isolated remote function onUpdateMessage(websubhub:UpdateMessage message, http:Headers headers)
                returns websubhub:Acknowledgement|websubhub:UpdateMessageError|error {
        if config:SECURITY_ON {
            check security:authorizePublisher(headers, message.hubTopic);
        }
        check self.updateMessage(message);
        return websubhub:ACKNOWLEDGEMENT;
    }

    isolated function updateMessage(websubhub:UpdateMessage msg) returns websubhub:UpdateMessageError? {

        string topicName = util:sanitizeTopicName(msg.hubTopic);
        error? topicIFNotExist = self.createTopicIFNotExist(topicName, "null");
        if (topicIFNotExist is error) {
            return error websubhub:UpdateMessageError(topicIFNotExist.message());
        }
        log:printDebug("Received publish message", topic = msg.hubTopic, message = msg.cloneReadOnly());
        error? errorResponse = persist:addUpdateMessage(topicName, msg);
        // TODO: remove this condition
        if errorResponse is websubhub:UpdateMessageError {
            log:printError("Error occurred while publishing the content ", errorMessage = errorResponse.message(), topic = topicName);
            return errorResponse;
        } else if errorResponse is error {
            log:printError("Error occurred while publishing the content ", errorMessage = errorResponse.message(), topic = topicName);
            return error websubhub:UpdateMessageError(errorResponse.message());
        }

    }

    isolated function createTopicIFNotExist(string topicName, string callback) returns error? {
        boolean topicAvailable = false;
        lock {
            topicAvailable = registeredTopicsCache.hasKey(topicName);
        }

        if !topicAvailable {
            websubhub:TopicRegistration topicRegistrationMsg = {
                topic: topicName
            };
            log:printInfo("Topic not found - Auto registering topic", topic = topicName, calback = callback);
            error? persistingResult = persist:addRegsiteredTopic(topicRegistrationMsg.cloneReadOnly());
            if persistingResult is error {
                log:printError("Error occurred while persisting the topic-auto-registration ", topic = topicName, callback = callback, err = persistingResult.message());
                return persistingResult;
            } else {
                log:printInfo("Topic auto registered", topic = topicName, callback = callback);
            }
        }
    }

};

