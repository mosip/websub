import ballerina/log;
import ballerinax/java.jdbc;
import ballerina/time;
import ballerina/stringutils;

public type HubPersistenceImpl object {

    private jdbc:Client jdbcClient;

    public function __init(jdbc:Client jdbcClient) {
        self.jdbcClient = jdbcClient;
    }

    # Adds or updates subscription details.
    # ```ballerina
    # error? result = hubPersistenceStore.addSubscription(subscriptionDetails);
    # ```
    #
    # + subscriptionDetails - The details of the subscription to add or update
    # + return - An `error` if an error occurred while adding the subscription or else `()` otherwise
    public function addSubscription(SubscriptionDetails subscriptionDetails) returns error? {
        var currentUTCTime = time:format(time:currentTime(), TIMESTAMP_PATTERN);
        string callback= stringutils:split(subscriptionDetails.callback, "[\\?|\\#]")[0];
        jdbc:Parameter p1 = {sqlType: jdbc:TYPE_VARCHAR, value: subscriptionDetails.topic};
        jdbc:Parameter p2 = {sqlType: jdbc:TYPE_VARCHAR, value: callback};
        jdbc:Parameter p3 = {sqlType: jdbc:TYPE_VARCHAR, value: subscriptionDetails.secret};
        jdbc:Parameter p4 = {sqlType: jdbc:TYPE_BIGINT, value: subscriptionDetails.leaseSeconds};
        jdbc:Parameter p5 = {sqlType: jdbc:TYPE_BIGINT, value: subscriptionDetails.createdAt};
        jdbc:Parameter p6 = {sqlType: jdbc:TYPE_BOOLEAN, value: true};
        jdbc:Parameter p7 = {sqlType: jdbc:TYPE_VARCHAR, value: HUB_ADMIN};
        jdbc:Parameter p8 = {sqlType: jdbc:TYPE_TIMESTAMP, value: currentUTCTime.toString()};
        jdbc:Parameter p9 = {sqlType: jdbc:TYPE_VARCHAR, value: ""};
        jdbc:Parameter p10 = {sqlType: jdbc:TYPE_TIMESTAMP, value: ""};
        jdbc:Parameter p11 = {sqlType: jdbc:TYPE_BOOLEAN, value: false};
        jdbc:Parameter p12 = {sqlType: jdbc:TYPE_TIMESTAMP, value: ""};

        var returned = self.jdbcClient->update(DELETE_FROM_SUBSCRIPTIONS, p7,p8,p1,p2);
        self.handleUpdate(returned, "delete subs if exist");
        returned = self.jdbcClient->update(INSERT_INTO_SUBSCRIPTIONS_TABLE, p1, p2,
            p3, p4, p5,p6,p7,p8,p9,p10,p11,p12);
        self.handleUpdate(returned, "insert new subs");
    }

    # Removes subscription details.
    # ```ballerina
    # error? result = hubPersistenceStore.removeSubscription(subscriptionDetails);
    # ```
    #
    # + subscriptionDetails - The details of the subscription to remove
    # + return - An `error` if an error occurred while removing the subscription or else `()` otherwise
    public function removeSubscription(SubscriptionDetails subscriptionDetails) returns error? {
        string callback= stringutils:split(subscriptionDetails.callback, "[\\?|\\#]")[0];
        var currentUTCTime = time:format(time:currentTime(), TIMESTAMP_PATTERN);
        jdbc:Parameter p1 = {sqlType: jdbc:TYPE_VARCHAR, value: subscriptionDetails.topic};
        jdbc:Parameter p2 = {sqlType: jdbc:TYPE_VARCHAR, value: callback};
        jdbc:Parameter p3= {sqlType: jdbc:TYPE_VARCHAR, value: HUB_ADMIN};
        jdbc:Parameter p4 = {sqlType: jdbc:TYPE_TIMESTAMP, value: currentUTCTime.toString()};
        var returned = self.jdbcClient->update(DELETE_FROM_SUBSCRIPTIONS, p3,p4,p1,p2);
        self.handleUpdate(returned, "Removed subscription");
    }

    # Function to add a topic.
    # ```ballerina
    # error? result = hubPersistenceStore.addTopic("topic");
    # ```
    #
    # + topic - The topic to add
    # + return - An `error` if an error occurred while adding the topic or else `()` otherwise
    public function addTopic(string topic) returns error? {
        var currentUTCTime = time:format(time:currentTime(), TIMESTAMP_PATTERN);
        jdbc:Parameter p1 = {sqlType: jdbc:TYPE_VARCHAR, value: topic};
        jdbc:Parameter p2 = {sqlType: jdbc:TYPE_VARCHAR, value: HUB_ADMIN};
        jdbc:Parameter p3 = {sqlType: jdbc:TYPE_TIMESTAMP, value: currentUTCTime.toString()};
        jdbc:Parameter p4 = {sqlType: jdbc:TYPE_VARCHAR, value: ""};
        jdbc:Parameter p5 = {sqlType: jdbc:TYPE_TIMESTAMP, value: ""};
        jdbc:Parameter p6 = {sqlType: jdbc:TYPE_BOOLEAN, value: false};
        jdbc:Parameter p7 = {sqlType: jdbc:TYPE_TIMESTAMP, value: ""};
        var returned = self.jdbcClient->update(INSERT_INTO_TOPICS, p1,p2,p3,p4,p5,p6,p7);
        self.handleUpdate(returned, "Add topic");
    }

    # Function to remove a topic.
    # ```ballerina
    # error? result = hubPersistenceStore.removeTopic("topic");
    # ```
    #
    # + topic - The topic to remove
    # + return - An `error` if an error occurred while removing the topic or else `()` otherwise
    public function removeTopic(string topic) returns error? {
        var currentUTCTime = time:format(time:currentTime(), TIMESTAMP_PATTERN);
        jdbc:Parameter p1 = {sqlType: jdbc:TYPE_VARCHAR, value: HUB_ADMIN};
        jdbc:Parameter p2 = {sqlType: jdbc:TYPE_TIMESTAMP, value: currentUTCTime.toString()};
        jdbc:Parameter p3 = {sqlType: jdbc:TYPE_TIMESTAMP, value: currentUTCTime.toString()};
        jdbc:Parameter p4 = {sqlType: jdbc:TYPE_VARCHAR, value: topic};
        var returned = self.jdbcClient->update(DELETE_FROM_TOPICS, p1,p2,p3,p4);
        self.handleUpdate(returned, "Removed topic");
    }

    # Function to retrieve subscription details of all subscribers.
    # ```ballerina
    # SubscriptionDetails[]|error result = hubPersistenceStore.retrieveAllSubscribers();
    # ```
    #
    # + return - An array of subscriber details or else an `error` if an error occurred while retrieving
    #            the subscriptions
    public function retrieveAllSubscribers() returns  @tainted SubscriptionDetails[]|error {
        SubscriptionDetails[] subscriptions = [];
        int subscriptionIndex = 0;
        var dbResult = self.jdbcClient->select(SELECT_FROM_SUBSCRIPTIONS, SubscriptionDetails);
        if (dbResult is table<record {}>) {
            while (dbResult.hasNext()) {
                var subscriptionDetails = trap <SubscriptionDetails>dbResult.getNext();
                if (subscriptionDetails is SubscriptionDetails) {
                    subscriptions[subscriptionIndex] = subscriptionDetails;
                    subscriptionIndex += 1;
                } else {
                    string errCause = <string>subscriptionDetails.detail()?.message;
                    log:printError("Error retreiving subscription details from the database: " + errCause);
                }
            }
        } else {
            string errCause = <string>dbResult.detail()?.message;
            log:printError("Error retreiving data from the database: " + errCause);
        }
        return subscriptions;
    }

    # Function to retrieve all registered topics.
    # ```ballerina
    # string[]|error result = hubPersistenceStore.retrieveTopics();
    # ```
    #
    # + return - An array of topics or else `error` if an error occurred while retrieving the topics
    public function retrieveTopics() returns  @tainted string[]|error {
        string[] topics = [];
        int topicIndex = 0;
        var dbResult = self.jdbcClient->select(SELECT_ALL_FROM_TOPICS, TopicRegistration);
        if (dbResult is table<record {}>) {
            while (dbResult.hasNext()) {
                var registrationDetails = trap <TopicRegistration>dbResult.getNext();
                if (registrationDetails is TopicRegistration) {
                    topics[topicIndex] = registrationDetails.topic;
                    topicIndex += 1;
                } else {
                    string errCause = <string>registrationDetails.detail()?.message;
                    log:printError("Error retreiving topic registration details from the database: " + errCause);
                }
            }
        } else {
            string errCause = <string>dbResult.detail()?.message;
            log:printError("Error retreiving data from the database: " + errCause);
        }
        return topics;
    }

    function handleUpdate(jdbc:UpdateResult|jdbc:Error returned, string message) {
        if (returned is jdbc:UpdateResult) {
            log:printDebug(message + " status: " + returned.updatedRowCount.toString());
        } else {
            log:printError(message + " failed: " + <string>returned.detail()?.message);
        }
    }
};
