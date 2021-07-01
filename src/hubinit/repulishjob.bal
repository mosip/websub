import ballerina/config;
import ballerina/log;
import ballerina/runtime;
import ballerina/websub;
import mosip/repository;
import mosip/services;

public type RepublishJob object {

    public function __init() {
    }
  
    service republishservice = service {

        resource function onTrigger(services:HubServiceImpl hubServiceImpl, websub:Hub webSubHub) {
            repository:RestartRepublishContentModel[] unsentMessages = hubServiceImpl.getUnsentMessages(config:getAsString("mosip.hub.restart_republish_time_offset"));
            if (unsentMessages.length() > 0) {
                foreach var unsentMessage in unsentMessages {
                    var publishResponse = webSubHub.publishUpdate(unsentMessage.topic, unsentMessage.message.toBytes());
                    if (publishResponse is error) {
                        log:printError("Error notifying hub: " +
                            <string>publishResponse.detail()?.message);
                    } else {
                        log:printInfo("republish notification successful!");
                    }
                    runtime:sleep(2000);
                }
            }
        }
    };

    public function getRepublishservice() returns service{
        return  self.republishservice;
    }
};
