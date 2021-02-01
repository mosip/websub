import ballerina/log;
import ballerina/time;
import ballerinax/java.jdbc;


public type DeliveryReportPersistence object {

    private jdbc:Client jdbcClient;

    public function __init(jdbc:Client jdbcClient) {
        self.jdbcClient = jdbcClient;
    }

    public function addSuccessDelivery(SucessDeliveryDetails successDeliveryDetails) returns error? {
        jdbc:Parameter msgID = {sqlType: jdbc:TYPE_VARCHAR, value: successDeliveryDetails.msgID};
        jdbc:Parameter subsID = {sqlType: jdbc:TYPE_VARCHAR, value: successDeliveryDetails.subsID};
        jdbc:Parameter deliverySuccessDTimes = {sqlType: jdbc:TYPE_TIMESTAMP, value: successDeliveryDetails.successDeliveryDTimes};
        jdbc:Parameter createdBy = {sqlType: jdbc:TYPE_VARCHAR, value: HUB_ADMIN};
        jdbc:Parameter createdDTimes = {sqlType: jdbc:TYPE_TIMESTAMP, value: successDeliveryDetails.successDeliveryDTimes};
        jdbc:Parameter updatedBy = {sqlType: jdbc:TYPE_VARCHAR, value: ""};
        jdbc:Parameter updatedDTimes = {sqlType: jdbc:TYPE_TIMESTAMP, value: ""};
        jdbc:Parameter isDeleted = {sqlType: jdbc:TYPE_BOOLEAN, value: false};
        jdbc:Parameter deletedDTimes = {sqlType: jdbc:TYPE_TIMESTAMP, value: ""};

        var returned = self.jdbcClient->update(INSERT_INTO_SUCCESS_DELIVERY_TABLE, msgID, subsID,
            deliverySuccessDTimes, createdBy, createdDTimes, updatedBy, updatedDTimes, isDeleted, deletedDTimes);
        self.handleUpdate(returned, "insert new delivery report");
    }

    public function addFailedDelivery(FailedDeliveryDetails failedDeliveryDetails) returns error? {
        var currentUTCTime = time:format(time:currentTime(), TIMESTAMP_PATTERN);
        jdbc:Parameter msgID = {sqlType: jdbc:TYPE_VARCHAR, value: failedDeliveryDetails.msgID};
        jdbc:Parameter subsID = {sqlType: jdbc:TYPE_VARCHAR, value: failedDeliveryDetails.subsID};
        jdbc:Parameter deliveryFailureDTimes = {sqlType: jdbc:TYPE_TIMESTAMP, value: failedDeliveryDetails.failedDeliveryDTimes};
        jdbc:Parameter reason = {sqlType: jdbc:TYPE_VARCHAR, value: failedDeliveryDetails.reason};
        jdbc:Parameter failureError = {sqlType: jdbc:TYPE_VARCHAR, value: failedDeliveryDetails.failureError};
        jdbc:Parameter createdBy = {sqlType: jdbc:TYPE_VARCHAR, value: HUB_ADMIN};
        jdbc:Parameter createdDTimes = {sqlType: jdbc:TYPE_TIMESTAMP, value: failedDeliveryDetails.failedDeliveryDTimes};
        jdbc:Parameter updatedBy = {sqlType: jdbc:TYPE_VARCHAR, value: ""};
        jdbc:Parameter updatedDTimes = {sqlType: jdbc:TYPE_TIMESTAMP, value: ""};
        jdbc:Parameter isDeleted = {sqlType: jdbc:TYPE_BOOLEAN, value: false};
        jdbc:Parameter deletedDTimes = {sqlType: jdbc:TYPE_TIMESTAMP, value: ""};

        var returned = self.jdbcClient->update(INSERT_INTO_FAILED_DELIVERY_TABLE, msgID, subsID, deliveryFailureDTimes, reason, failureError,
            createdBy, createdDTimes, updatedBy, updatedDTimes, isDeleted, deletedDTimes);
        self.handleUpdate(returned, "insert new delivery report");
    }

    public function removeFailedDelivery(FailedDeliveryDetails failedDeliveryDetails) returns error? {
        var currentUTCTime = time:format(time:currentTime(), TIMESTAMP_PATTERN);
        jdbc:Parameter msgID = {sqlType: jdbc:TYPE_VARCHAR, value: failedDeliveryDetails.msgID};
        jdbc:Parameter subsID = {sqlType: jdbc:TYPE_VARCHAR, value: failedDeliveryDetails.subsID};
        jdbc:Parameter updatedBy= {sqlType: jdbc:TYPE_VARCHAR, value: HUB_ADMIN};
        jdbc:Parameter updatedDTimes = {sqlType: jdbc:TYPE_TIMESTAMP, value: currentUTCTime.toString()};
        var returned = self.jdbcClient->update(DELETE_FROM_FAILED_DELIVERY_TABLE,updatedBy,updatedDTimes, msgID, subsID);
        self.handleUpdate(returned, "remove failed query new delivery report");
    }

    public function getFailedDeliveryBySubID(string subID,string timestamp,int count) returns @tainted string[] {
        string[] msgIDs=[];
        int msgIDIndex = 0;
        jdbc:Parameter subsIDParameter = {sqlType: jdbc:TYPE_VARCHAR, value: subID};
        jdbc:Parameter timestampParameter= {sqlType: jdbc:TYPE_TIMESTAMP, value: timestamp};
        jdbc:Parameter resultCount= {sqlType: jdbc:TYPE_INTEGER, value: count};
        var dbResult = self.jdbcClient->select(SELECT_FROM_FAILED_DELIVERY_TABLE_BY_SUBID_AND_TIMESTAMP,FailedDeliveryDetails,subsIDParameter,timestampParameter,resultCount);
        if (dbResult is table<record {}>) {
            while (dbResult.hasNext()) {
                var failedDeliveryDetails = trap <FailedDeliveryDetails>dbResult.getNext();
                if (failedDeliveryDetails is FailedDeliveryDetails) {
                    msgIDs[msgIDIndex] = failedDeliveryDetails.msgID;
                    msgIDIndex += 1;
                } else {
                    string errCause = <string>failedDeliveryDetails.detail()?.message;
                    log:printError("Error retreiving failed delivery from subID from the database: " + errCause);
                }
            }
        } else {
            string errCause = <string>dbResult.detail()?.message;
            log:printError("Error retreiving data from the database: " + errCause);
        }
        return msgIDs;
    }

    public function updateLastFetchTimestamp(string msgID,string subID,string lastFetchDTimes){
        var currentUTCTime = time:format(time:currentTime(), TIMESTAMP_PATTERN);
        jdbc:Parameter msgIDParameter = {sqlType: jdbc:TYPE_VARCHAR, value: msgID};
        jdbc:Parameter subIDParameter = {sqlType: jdbc:TYPE_VARCHAR, value: subID};
        jdbc:Parameter updatedByParameter= {sqlType: jdbc:TYPE_VARCHAR, value: HUB_ADMIN};
        jdbc:Parameter updatedDTimesParameter = {sqlType: jdbc:TYPE_TIMESTAMP, value: lastFetchDTimes};
        jdbc:Parameter lastFetchDTimesParameter = {sqlType: jdbc:TYPE_TIMESTAMP, value: lastFetchDTimes};
        var returned = self.jdbcClient->update(UPDATE_LAST_FETCH_TIMESTAMP_INTO_FAILED_DELIVERY_TABLE,lastFetchDTimesParameter,updatedByParameter,updatedDTimesParameter, msgIDParameter,subIDParameter);
        self.handleUpdate(returned, "failed update last fetch timestamp");
    }

    function handleUpdate(jdbc:UpdateResult|jdbc:Error returned, string message) {
        if (returned is jdbc:UpdateResult) {
            log:printDebug(message + " status: " + returned.updatedRowCount.toString());
        } else {
            log:printError(message + " failed: " + <string>returned.detail()?.message);
        }
    }

};
