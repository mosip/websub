import ballerina/lang.'string;
import ballerina/lang.'array;
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

    public function findMessageByHash(string hash) returns @tainted MessageDetails[] {
        MessageDetails[] messageDetails = [];
        int messageIndex = 0;
        jdbc:Parameter hashParameter = {sqlType: jdbc:TYPE_VARCHAR, value: hash};
        var dbResult = self.jdbcClient->select(SELECT_FROM_MESSAGE_BY_HASH, MessageDetails, hashParameter);

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


    public function findMessageByTopicAndMessage(string topic, string message) returns @tainted MessageDetails {
        MessageDetails messageDetails = {};

        jdbc:Parameter topicParameter = {sqlType: jdbc:TYPE_VARCHAR, value: topic};
        jdbc:Parameter messageParameter = {sqlType: jdbc:TYPE_VARCHAR, value: message};

        var dbResult = self.jdbcClient->select(SELECT_FROM_MESSAGE_BY_TOPIC_MESSAGE, MessageDetails, topic, message);

        if (dbResult is table<record {}>) {
            while (dbResult.hasNext()) {
                var messageDetail = trap <MessageDetails>dbResult.getNext();
                if (messageDetail is MessageDetails) {
                    messageDetails = messageDetail;
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

    public function findMessageByIDs(string[] msgIDs) returns @tainted FailedContentModel[] {

        FailedContentModel[] failedContentModels = [];
        int index = 0;
        string IDs = "";
        foreach string msgID in msgIDs {
            if (index == msgIDs.length() - 1) {
                    IDs=IDs.concat(msgID);
            } else {
                    IDs=IDs.concat(msgID,",");
            }
            index = index + 1;
        }
        jdbc:Parameter IDParamater = {sqlType: jdbc:TYPE_VARCHAR, value: IDs};

        index = 0;
        var dbResult = self.jdbcClient->select(SELECT_FROM_MESSAGE_BY_ID, MessageDetails, IDs);

        if (dbResult is table<record {}>) {
            while (dbResult.hasNext()) {
                var messageDetail = trap <MessageDetails>dbResult.getNext();
                if (messageDetail is MessageDetails) {
                    string messageDecodedString = "";
                    byte[]|error messageDecodedBytes = 'array:fromBase64(messageDetail.message);
                    if (messageDecodedBytes is byte[]) {
                        string|error msgDecodedString = 'string:fromBytes(messageDecodedBytes);
                        if (msgDecodedString is string) {
                            messageDecodedString = msgDecodedString;
                        }
                    }
                    failedContentModels[index] = {
                        message: messageDecodedString,
                        timestamp: messageDetail.publishedDTimes
                    };
                    index = index + 1;
                } else {
                    string errCause = <string>messageDetail.detail()?.message;
                    log:printError("Error retreiving failed delivery from subID from the database: " + errCause);
                }
            }
        } else {
            string errCause = <string>dbResult.detail()?.message;
            log:printError("Error retreiving data from the database: " + errCause);
        }
        return failedContentModels;
    }

    function handleUpdate(jdbc:UpdateResult|jdbc:Error returned, string message) {
        if (returned is jdbc:UpdateResult) {
            log:printDebug(message + " status: " + returned.updatedRowCount.toString());
        } else {
            log:printError(message + " failed: " + <string>returned.detail()?.message);
        }
    }





    public function getUnsentMessages(string timestamp) returns @tainted RestartRepublishContentModel[]{     
      jdbc:Parameter timestampParameter = {sqlType: jdbc:TYPE_TIMESTAMP, value: timestamp};
      RestartRepublishContentModel[] restartRepublishContentModels = [];
        int index = 0;
        var dbResult = self.jdbcClient->select(RESTART_REPUBLISH_MESSAGES, RestartRepublishContentModel,timestampParameter,timestampParameter,timestampParameter);

        if (dbResult is table<record {}>) {
            while (dbResult.hasNext()) {
                var restartRepublishContent = trap <RestartRepublishContentModel>dbResult.getNext();
                if (restartRepublishContent is RestartRepublishContentModel) {
                    string messageDecodedString = "";
                    byte[]|error messageDecodedBytes = 'array:fromBase64(restartRepublishContent.message);
                    if (messageDecodedBytes is byte[]) {
                        string|error msgDecodedString = 'string:fromBytes(messageDecodedBytes);
                        if (msgDecodedString is string) {
                            messageDecodedString = msgDecodedString;
                        }
                    }
                    restartRepublishContentModels[index] = {
                        message: messageDecodedString,
                        topic: restartRepublishContent.topic
                    };
                    index = index + 1;
                } else {
                    string errCause = <string>restartRepublishContent.detail()?.message;
                    log:printError("Error retreiving unsend messaged from message store: " + errCause);
                }
            }
        } else {
            string errCause = <string>dbResult.detail()?.message;
            log:printError("Error retreiving data from the database: " + errCause);
        }
        return restartRepublishContentModels;
    }
};
