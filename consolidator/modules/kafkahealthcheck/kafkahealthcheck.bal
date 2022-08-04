import ballerina/jballerina.java;
import consolidatorService.config;
import ballerina/log;

public function getAllTopicsKafka() returns handle|error? {
    handle bootStrapServer = java:fromString(config:KAFKA_BOOTSTRAP_NODE);
    handle newMosipKafkaAdminClientResult = newMosipKafkaAdminClient(bootStrapServer);
    log:printInfo("Checking if metadata Topics are present");
    handle|error? result = trap getAllTopics(newMosipKafkaAdminClientResult);
    return result;
}

function newMosipKafkaAdminClient(handle bootstrapServers) returns handle = @java:Constructor {
    'class: "io.mosip.kafkaadminclient.MosipKafkaAdminClient",
    paramTypes: ["java.lang.String"]
} external;

function getAllTopics(handle adminClinetObject) returns handle|error? = @java:Method {
    name: "getAllTopics",
    'class: "io.mosip.kafkaadminclient.MosipKafkaAdminClient"
} external;

