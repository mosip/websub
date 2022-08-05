import ballerina/jballerina.java;
import consolidatorService.config;
import ballerina/log;

public function describeTopicKafka(string topic) returns handle|error? {
    handle bootStrapServer = java:fromString(config:KAFKA_BOOTSTRAP_NODE);
    handle newMosipKafkaAdminClientResult = newMosipKafkaAdminClient(bootStrapServer);
    handle|error? result = trap describeTopic(newMosipKafkaAdminClientResult, java:fromString(topic));
    return result;
}

function newMosipKafkaAdminClient(handle bootstrapServers) returns handle = @java:Constructor {
    'class: "io.mosip.kafkaadminclient.MosipKafkaAdminClient",
    paramTypes: ["java.lang.String"]
} external;

function describeTopic(handle adminClinetObject, handle topic) returns handle|error? = @java:Method {
    name: "describeTopic",
    'class: "io.mosip.kafkaadminclient.MosipKafkaAdminClient",
    paramTypes: ["java.lang.String"]
} external;

