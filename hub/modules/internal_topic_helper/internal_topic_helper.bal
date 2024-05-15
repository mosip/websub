import ballerina/jballerina.java;
import kafkaHub.config;
import ballerina/log;

public function isTopicsPresentKafka() returns boolean|error? {
    handle bootStrapServer = java:fromString(config:KAFKA_BOOTSTRAP_NODE);
    handle newMosipKafkaAdminClientResult = newMosipKafkaAdminClient(bootStrapServer);
    log:printInfo("Checking if metadata Topics are present");
    boolean|error? result = trap isTopicsPresent(newMosipKafkaAdminClientResult, java:fromString(config:META_TOPICS));
    log:printInfo("Metadata Topics are present", isPresent = result);
    return result;
}

function newMosipKafkaAdminClient(handle bootstrapServers) returns handle = @java:Constructor {
    'class: "io.mosip.kafkaadminclient.MosipKafkaAdminClient",
    paramTypes: ["java.lang.String"]
} external;

function isTopicsPresent(handle adminClinetObject, handle topics) returns boolean|error? = @java:Method {
    name: "isTopicsPresent",
    'class: "io.mosip.kafkaadminclient.MosipKafkaAdminClient",
    paramTypes: ["java.lang.String"]
} external;

