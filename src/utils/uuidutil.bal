import ballerina/java;


public function createRandomUUID() returns handle = @java:Method {
    name: "randomUUID",
    class: "java.util.UUID"
} external;
