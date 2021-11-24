public type HealthCheckResp record {|
    string status;
    map<anydata> details;
|};

public type DiskSpaceMetaData record {|
    int total;
    int free;
|};

public type KafkaMetaData record {|
    string producerStatus;
    string consumerStatus;
|};