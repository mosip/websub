import ballerina/log;
import ballerina/stringutils;
import ballerina/time;
import ballerinax/java.jdbc;


public type SubsOperations object {

    private jdbc:Client jdbcClient;

    public function __init(jdbc:Client jdbcClient) {
        self.jdbcClient = jdbcClient;
    }

    public function getSubscription(string topic, string callback) returns @tainted SubscriptionExtendedDetails {
        string callbackParameter = stringutils:split(callback, "[\\?|\\#]")[0];
        var currentUTCTime = time:format(time:currentTime(), TIMESTAMP_PATTERN);
        jdbc:Parameter topicParameter = {sqlType: jdbc:TYPE_VARCHAR, value: topic};
        jdbc:Parameter callbackJDBCParameter = {sqlType: jdbc:TYPE_VARCHAR, value: callback};
        jdbc:Parameter updatedBy = {sqlType: jdbc:TYPE_VARCHAR, value: HUB_ADMIN};
        jdbc:Parameter updatedDTimes = {sqlType: jdbc:TYPE_TIMESTAMP, value: currentUTCTime.toString()};
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
        } else {
            string errCause = <string>dbResult.detail()?.message;
            log:printError("Error retreiving data from the database: " + errCause);
        }
        return subscriptionResult;

    }
};
