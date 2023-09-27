public type HealthCheckResp record {|
    string status;
    map<anydata> details;
|};

public type DiskSpaceMetaData record {|
    int total;
    int free;
    int threshold;
|};