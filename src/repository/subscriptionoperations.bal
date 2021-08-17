import ballerina/log;
import ballerina/stringutils;
import ballerinax/java.jdbc;


public type SubsOperations object {

    private jdbc:Client jdbcClient;

    public function __init(jdbc:Client jdbcClient) {
        self.jdbcClient = jdbcClient;
    }

    public function getSubscription(string topic, string callback) returns @tainted SubscriptionExtendedDetails {
        string callbackParameter = stringutils:split(callback, "[\\?|\\#]")[0];
        jdbc:Parameter topicParameter = {sqlType: jdbc:TYPE_VARCHAR, value: topic};
        jdbc:Parameter callbackJDBCParameter = {sqlType: jdbc:TYPE_VARCHAR, value: callback};
        var dbResult = self.jdbcClient->select(SELECT_FROM_SUBSCRIPTIONS_BY_TOPIC_CALLBACK, SubscriptionExtendedDetails, topicParameter,
            callbackJDBCParameter);
        SubscriptionExtendedDetails subscriptionResult = {};
        if (dbResult is table<record {}>) {
            while (dbResult.hasNext()) {
                var subscriptionExtendedDetails = trap <SubscriptionExtendedDetails>dbResult.getNext();
                if (subscriptionExtendedDetails is SubscriptionExtendedDetails) {
                    subscriptionResult = subscriptionExtendedDetails;
                } else {
                    string errCause = <string>subscriptionExtendedDetails.detail()?.message;
                    log:printError("Error retreiving topic registration details from the database: " + errCause);
                }
            }
            dbResult.close();
        } else {
            string errCause = <string>dbResult.detail()?.message;
            log:printError("Error retreiving data from the database: " + errCause);
        }
        return subscriptionResult;

    }

    // get subscription from history table
    public function getSubscriptionFromHistory(string topic, string callback, string publishedTimes) returns @tainted SubscriptionExtendedDetails {
        string callbackParameter = stringutils:split(callback, "[\\?|\\#]")[0];
        jdbc:Parameter topicParameter = {sqlType: jdbc:TYPE_VARCHAR, value: topic};
        jdbc:Parameter callbackJDBCParameter = {sqlType: jdbc:TYPE_VARCHAR, value: callback};
        jdbc:Parameter pubDTimes = {sqlType: jdbc:TYPE_TIMESTAMP, value: publishedTimes};
        var dbResult = self.jdbcClient->select(SELECT_FROM_SUBSCRIPTIONS_BY_TOPIC_CALLBACK_HISTORY, SubscriptionExtendedDetails, topicParameter,
            callbackJDBCParameter,pubDTimes,pubDTimes);
        SubscriptionExtendedDetails subscriptionResult = {};
        if (dbResult is table<record {}>) {
            while (dbResult.hasNext()) {
                var subscriptionExtendedDetails = trap <SubscriptionExtendedDetails>dbResult.getNext();
                if (subscriptionExtendedDetails is SubscriptionExtendedDetails) {
                    subscriptionResult = subscriptionExtendedDetails;
                } else {
                    string errCause = <string>subscriptionExtendedDetails.detail()?.message;
                    log:printError("Error retreiving topic registration details from the database: " + errCause);
                }
            }
            dbResult.close();
        } else {
            string errCause = <string>dbResult.detail()?.message;
            log:printError("Error retreiving data from the database: " + errCause);
        }
        return subscriptionResult;

    }

    // get subscription from history table
    public function getSubscriptionsFromHistory(string topic, string callback, string timestamp) returns @tainted SubscriptionExtendedDetails[] {
        string callbackParameter = stringutils:split(callback, "[\\?|\\#]")[0];
        jdbc:Parameter topicParameter = {sqlType: jdbc:TYPE_VARCHAR, value: topic};
        jdbc:Parameter callbackJDBCParameter = {sqlType: jdbc:TYPE_VARCHAR, value: callback};
        jdbc:Parameter timestampParam = {sqlType: jdbc:TYPE_TIMESTAMP, value: timestamp};
        var dbResult = self.jdbcClient->select(SELECT_FROM_SUBSCRIPTIONS_BY_TOPIC_CALLBACK_HISTORY_FAILED, SubscriptionExtendedDetails, topicParameter,
            callbackJDBCParameter,timestampParam);
        int subscriptionIndex = 0;    
        SubscriptionExtendedDetails[] subscriptionResult = [];
        if (dbResult is table<record {}>) {
            while (dbResult.hasNext()) {
                var subscriptionExtendedDetails = trap <SubscriptionExtendedDetails>dbResult.getNext();
                if (subscriptionExtendedDetails is SubscriptionExtendedDetails) {
                    subscriptionResult[subscriptionIndex] = subscriptionExtendedDetails;
                    subscriptionIndex += 1;
                } else {
                    string errCause = <string>subscriptionExtendedDetails.detail()?.message;
                    log:printError("Error retreiving topic registration details from the database: " + errCause);
                }
            }
            dbResult.close();
        } else {
            string errCause = <string>dbResult.detail()?.message;
            log:printError("Error retreiving data from the database: " + errCause);
        }
        return subscriptionResult;

    }
};
