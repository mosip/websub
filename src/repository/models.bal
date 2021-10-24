public type SubscriptionDetails record {|
    string topic = "";
    string callback = "";
    string secret = "";
    int leaseSeconds = 0;
    int createdAt = 0;
|};

public type SubscriptionExtendedDetails record {|
    string id ="";
    string topic = "";
    string callback = "";
    string secret = "";
    int leaseSeconds = 0;
    int createdAt = 0;
|};

public type TopicRegistration record {|
    string topic = "";
|};

public type MessageDetails record {|
    string id = "";
    string message = "";
    string topic = "";
    string publisher = "";
    string publishedDTimes = "";
    string hubInstanceID = "";
    string msgTopicHash = "";
|};

public type SucessDeliveryDetails record {|
    string msgID = "";
    string subsID = "";
    string successDeliveryDTimes = "";
|};

public type FailedDeliveryDetails record {|
    string msgID = "";
    string subsID = "";
    string failedDeliveryDTimes = "";
    string reason = "";
    string failureError = "";
|};

public type FailedDeliveryMsgIDs record {|
    string msgID = "";
|};

public type FailedContentPullRespModel record {|
    FailedContentModel[] failedcontents = [];
|};

public type FailedContentModel record {|
    string message = "";
    string timestamp = "";
|};

public type RestartRepublishContentModel record {|
    string message = "";
    string topic = "";
|};