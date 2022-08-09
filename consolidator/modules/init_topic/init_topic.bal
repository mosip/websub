import ballerina/jballerina.java;
import consolidatorService.config;
import ballerina/log;

public function createTopics() returns error? {
    handle bootStrapServer = java:fromString(config:KAFKA_BOOTSTRAP_NODE);
    handle newMosipKafkaAdminClientResult = newMosipKafkaAdminClient(bootStrapServer);
    foreach string topic in config:META_TOPICS {
        log:printInfo("Creating topic with single partition", topic = topic);
        error? result = trap createTopic(newMosipKafkaAdminClientResult, java:fromString(topic));
        if result is error {
            error cause = <error>result.detail().get("cause");
            if (cause.message() == "org.apache.kafka.common.errors.TopicExistsException") {
                log:printWarn(cause.toString());
            } else {
                return result;
            }
        }
    }

}

function newMosipKafkaAdminClient(handle bootstrapServers) returns handle = @java:Constructor {
    'class: "io.mosip.kafkaadminclient.MosipKafkaAdminClient",
    paramTypes: ["java.lang.String"]
} external;

function createTopic(handle adminClinetObject, handle topicName) returns error? = @java:Method {
    name: "createTopic",
    'class: "io.mosip.kafkaadminclient.MosipKafkaAdminClient",
    paramTypes: ["java.lang.String"]
} external;

