import ballerina/http;
import ballerina/io;
import ballerina/java;
import ballerina/lang.'string;
import ballerina/log;
import ballerina/time;
import ballerina/config;
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
            log:printDebug("sub id for notification "+subscriptionExtendedDetails.id);
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
        string payloadError = "";
        if (response is http:Response) {
            json|http:ClientError? payloadErrorJSON = response.getJsonPayload();
            if (payloadErrorJSON is json) {
                payloadError = payloadErrorJSON.toJsonString();
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


    public function getFailedContent(string subscriberSignature, string topic, string callback, string timestamp, int messagecount) returns @untainted repository:FailedContentPullRespModel|error {
        int count=messagecount;
        repository:SubscriptionExtendedDetails subscriptionExtendedDetails = self.subsOperations.getSubscription(topic, callback);
        string hmacSubsSignature = "";
        if(count == 0){
        hmacSubsSignature = utils:hmacSha256(topic + callback + timestamp, subscriptionExtendedDetails.secret);
        count=config:getAsInt("mosip.hub.message_count_default", 10);
        }else{
        hmacSubsSignature = utils:hmacSha256(topic + callback + timestamp + count.toString(), subscriptionExtendedDetails.secret);
        
        }
        if (hmacSubsSignature != subscriberSignature) {
            return error("SIGNATUREMATCHERROR", message = "hmac didnot match");
        }
        string[] msgIDs = self.deliveryReportPersistence.getFailedDeliveryBySubID(subscriptionExtendedDetails.id, timestamp, count);
        repository:FailedContentModel[] failedContentModels = self.messagePersistenceImpl.findMessageByIDs(msgIDs);
        repository:FailedContentPullRespModel failedContentPullRespModel = {
            failedcontents: failedContentModels
        };
        return failedContentPullRespModel;


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



    public function getUnsentMessages(string timestamp) returns @tainted repository:RestartRepublishContentModel[] {
    return self.messagePersistenceImpl.getUnsentMessages(timestamp);
    }
};
