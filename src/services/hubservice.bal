import ballerina/http;
import ballerina/io;
import ballerina/java;
import ballerina/lang.'string;
import ballerina/log;
import ballerina/time;
import ballerina/websub;
import mosip/repository;
import mosip/utils;



public type HubServiceImpl object {


    private repository:DeliveryReportPersistence deliveryReportPersistence;
    private repository:MessagePersistenceImpl messagePersistenceImpl;
    private repository:SubsOperations subsOperations;
    public function __init(repository:DeliveryReportPersistence deliveryReportPersistence, repository:MessagePersistenceImpl messagePersistenceImpl, repository:SubsOperations subsOperations) {
        self.deliveryReportPersistence = deliveryReportPersistence;
        self.messagePersistenceImpl = messagePersistenceImpl;
        self.subsOperations = subsOperations;
    }

    public function onMessageReceived(string topic, string message) {
        var uuidresult = utils:createRandomUUID();
        string? uuid = java:toString(uuidresult);
        if (uuid is ()) {

        } else {
            repository:MessageDetails? alreadyExistMessageDetails = self.getMsg(topic, message);

            if (alreadyExistMessageDetails is repository:MessageDetails) {
                log:printDebug("Message already exist for that topic skipping insert");
            } else {

                string base64EncodedMessage = message.toBytes().toBase64();
                repository:MessageDetails messageDetails = {
                    id: uuid,
                    message: base64EncodedMessage,
                    topic: topic,
                    publisher: "DEFAULTPUBLISHER",
                    publishedDTimes: time:format(time:currentTime(), repository:TIMESTAMP_PATTERN).toString(),
                    hubInstanceID: "DEFAULTINSTANCEID",
                    msgTopicHash: utils:hashSha256(topic.concat(base64EncodedMessage))

                };
                var result = self.messagePersistenceImpl.addMessage(messageDetails);
            }
        }
    }

    public function onSucessDelivery(string callback, string topic, websub:WebSubContent content) {
        string|xml|json|byte[]|io:ReadableByteChannel payloadBytes = content.payload;
        string|error message = "";
        if (payloadBytes is byte[]) {
            message = 'string:fromBytes(payloadBytes);

        }
        repository:MessageDetails? messageDetails = {};
        if (message is string) {
            messageDetails = self.getMsg(topic, message);
        }
        if (messageDetails is repository:MessageDetails) {
            repository:SubscriptionExtendedDetails subscriptionExtendedDetails = self.subsOperations.getSubscription(topic, callback);
            repository:SucessDeliveryDetails sucessDeliveryDetails = {
                msgID: messageDetails.id,
                subsID: subscriptionExtendedDetails.id,
                successDeliveryDTimes: time:format(time:currentTime(), repository:TIMESTAMP_PATTERN).toString()
            };
            var result = self.deliveryReportPersistence.addSuccessDelivery(sucessDeliveryDetails);
        }
    }

    public function onFailedDelivery(string callback, string topic, websub:WebSubContent content, http:Response|error response, websub:FailureReason reason) {
     
        string|xml|json|byte[]|io:ReadableByteChannel payloadBytes = content.payload;
        string|error message = "";
        if (payloadBytes is byte[]) {
            message = 'string:fromBytes(payloadBytes);

        }
        repository:MessageDetails? messageDetails = {};
        if (message is string) {
            messageDetails = self.getMsg(topic, message);
        }
        string payloadError="";
        if(response is http:Response){
          json|http:ClientError? payloadErrorJSON =response.getJsonPayload();
           if(payloadErrorJSON is json){
               payloadError=payloadErrorJSON.toJsonString();
             }
        }
        if (messageDetails is repository:MessageDetails) {
            repository:SubscriptionExtendedDetails subscriptionExtendedDetails = self.subsOperations.getSubscription(topic, callback);
            repository:FailedDeliveryDetails failedDeliveryDetails = {
                msgID: messageDetails.id,
                subsID: subscriptionExtendedDetails.id,
                failedDeliveryDTimes: time:format(time:currentTime(), repository:TIMESTAMP_PATTERN).toString(),
                reason: reason.toString(),
                failureError: payloadError
            };
            var result = self.deliveryReportPersistence.addFailedDelivery(failedDeliveryDetails);
        }
    }

    public function getMsg(string topic, string message) returns @tainted repository:MessageDetails? {
        string base64EncodedMessage = message.toBytes().toBase64();
        string hash = utils:hashSha256(topic.concat(base64EncodedMessage));
        repository:MessageDetails[] messageDetails = self.messagePersistenceImpl.findMessageByHash(hash);
        if (messageDetails.length() > 1) {
            return self.messagePersistenceImpl.findMessageByTopicAndMessage(topic, base64EncodedMessage);
        } else {
            if (messageDetails.length() == 1) {
                return messageDetails[0];
            } else {
                return ();
            }
        }
    }


};
