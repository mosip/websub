import ballerina/jballerina.java;
import ballerina/log;
import consolidatorService.config; 

public function createTopics(){
log:printInfo("createTopics",bootStrapServer=config:KAFKA_BOOTSTRAP_NODE);
 handle bootStrapServer = java:fromString(config:KAFKA_BOOTSTRAP_NODE);
 log:printInfo("createTopics-bootStrapServer",bootStrapServer=bootStrapServer.toBalString());
 handle newMosipKafkaAdminClientResult = newMosipKafkaAdminClient(bootStrapServer);
 log:printInfo("createTopics-newMosipKafkaAdminClientResult",newMosipKafkaAdminClientResult=newMosipKafkaAdminClientResult.toBalString());
 createTopic(newMosipKafkaAdminClientResult,java:fromString("admin-topic-check"));
}


function newMosipKafkaAdminClient(handle bootstrapServers) returns handle = @java:Constructor {
   'class: "com.example.kafkaadminclient.MosipKafkaAdminClient",
   paramTypes: ["java.lang.String"]
} external;

function createTopic(handle adminClinetObject,handle topicName) = @java:Method {
    name: "createTopic",
    'class: "com.example.kafkaadminclient.MosipKafkaAdminClient",
    paramTypes: ["java.lang.String"]
} external;

