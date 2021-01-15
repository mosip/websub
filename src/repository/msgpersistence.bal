import ballerina/log;
import ballerina/time;
import ballerinax/java.jdbc;

public type MessagePersistenceImpl object {

    private jdbc:Client jdbcClient;

    public function __init(jdbc:Client jdbcClient) {
        self.jdbcClient = jdbcClient;
    }

    public function addMessage(MessageDetails messageDetails) returns error? {
        var currentUTCTime = time:format(time:currentTime(), TIMESTAMP_PATTERN);
        jdbc:Parameter id = {sqlType: jdbc:TYPE_VARCHAR, value: messageDetails.id};
        jdbc:Parameter message = {sqlType: jdbc:TYPE_VARCHAR, value: messageDetails.message};
        jdbc:Parameter topic = {sqlType: jdbc:TYPE_VARCHAR, value: messageDetails.topic};
        jdbc:Parameter publisher = {sqlType: jdbc:TYPE_VARCHAR, value: messageDetails.publisher};
        jdbc:Parameter publishedDTimes = {sqlType: jdbc:TYPE_TIMESTAMP, value: messageDetails.publishedDTimes};
        jdbc:Parameter hubInstanceID = {sqlType: jdbc:TYPE_VARCHAR, value: messageDetails.hubInstanceID};
        jdbc:Parameter messageTopicHash = {sqlType: jdbc:TYPE_VARCHAR, value: messageDetails.msgTopicHash};
        jdbc:Parameter createdBy = {sqlType: jdbc:TYPE_VARCHAR, value: HUB_ADMIN};
        jdbc:Parameter createdDTimes = {sqlType: jdbc:TYPE_TIMESTAMP, value: messageDetails.publishedDTimes};
        jdbc:Parameter updatedBy = {sqlType: jdbc:TYPE_VARCHAR, value: ""};
        jdbc:Parameter updatedDTimes = {sqlType: jdbc:TYPE_TIMESTAMP, value: ""};
        jdbc:Parameter isDeleted = {sqlType: jdbc:TYPE_BOOLEAN, value: false};
        jdbc:Parameter deletedDTimes = {sqlType: jdbc:TYPE_TIMESTAMP, value: ""};

        var returned = self.jdbcClient->update(INSERT_INTO_MESSAGE_TABLE, id, message,
            topic, publisher, publishedDTimes, hubInstanceID, messageTopicHash, createdBy, createdDTimes, updatedBy, updatedDTimes, isDeleted, deletedDTimes);
        self.handleUpdate(returned, "insert new message");
    }

    public function findMessageByHash(string hash) returns @tainted MessageDetails[]{
     MessageDetails[] messageDetails = [];
        int messageIndex = 0;
     jdbc:Parameter hashParameter = {sqlType: jdbc:TYPE_VARCHAR, value: hash};
     var dbResult = self.jdbcClient->select(SELECT_FROM_MESSAGE_BY_HASH,MessageDetails, hashParameter);

        if (dbResult is table<record {}>) {
            while (dbResult.hasNext()) {
                var messageDetail = trap <MessageDetails>dbResult.getNext();
                if (messageDetail is MessageDetails) {
                    messageDetails[messageIndex] = messageDetail;
                    messageIndex += 1;
                } else {
                    string errCause = <string>messageDetail.detail()?.message;
                    log:printError("Error retreiving topic registration details from the database: " + errCause);
                }
            }
        } else {
            string errCause = <string>dbResult.detail()?.message;
            log:printError("Error retreiving data from the database: " + errCause);
        }
        return messageDetails;
    }


    public function findMessageByTopicAndMessage(string topic,string message) returns @tainted MessageDetails{
     MessageDetails messageDetails = {};
     
        jdbc:Parameter topicParameter = {sqlType: jdbc:TYPE_VARCHAR, value: topic};
        jdbc:Parameter messageParameter = {sqlType: jdbc:TYPE_VARCHAR, value: message};
        
     var dbResult = self.jdbcClient->select(SELECT_FROM_MESSAGE_BY_TOPIC_MESSAGE,MessageDetails, topic,message);

        if (dbResult is table<record {}>) {
            while (dbResult.hasNext()) {
                var messageDetail = trap <MessageDetails>dbResult.getNext();
                if (messageDetail is MessageDetails) {
                    messageDetails= messageDetail;
                } else {
                    string errCause = <string>messageDetail.detail()?.message;
                    log:printError("Error retreiving topic registration details from the database: " + errCause);
                }
            }
        } else {
            string errCause = <string>dbResult.detail()?.message;
            log:printError("Error retreiving data from the database: " + errCause);
        }
        return messageDetails;
    }

    function handleUpdate(jdbc:UpdateResult|jdbc:Error returned, string message) {
        if (returned is jdbc:UpdateResult) {
            log:printDebug(message + " status: " + returned.updatedRowCount.toString());
        } else {
            log:printError(message + " failed: " + <string>returned.detail()?.message);
        }
    }



    
};
