import ballerina/config;
import ballerina/log;
import ballerina/runtime;
import ballerina/websub;
import mosip/repository;
import mosip/services;
import ballerina/time;


public type RepublishJob object {

    public function __init() {
    }
  
    service republishservice = service {
    
        resource function onTrigger(services:HubServiceImpl hubServiceImpl, websub:Hub webSubHub) {
            string timestamp = config:getAsString("mosip.hub.restart_republish_time_offset");
            time:TimeZone zoneIdValue = { id: "Z" };
            time:Time currentUTCTime = { time: time:currentTime().time, zone: zoneIdValue };
            time:Time unsentMessageTimestampLimit = time:subtractDuration(currentUTCTime,0,0,0,0,config:getAsInt("mosip.hub.restart_republish_time_limit"),0,0);
            string unsentMessageTimestampLimitString = time:format(unsentMessageTimestampLimit, repository:TIMESTAMP_PATTERN).toString();
            repository:RestartRepublishContentModel[] unsentMessages = hubServiceImpl.getUnsentMessages(timestamp,unsentMessageTimestampLimitString);
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
            //config:setConfig("mosip.hub.restart_republish_time_offset",unsentMessageTimestampLimitString);
            
        }
    };

    public function getRepublishservice() returns service{
        return  self.republishservice;
    }
};
