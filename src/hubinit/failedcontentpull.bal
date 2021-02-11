import ballerina/http;
import mosip/repository;
import ballerina/lang.'int;
import ballerina/config;

@http:ServiceConfig {
    basePath: "/failedcontent"
}
service failedcontent on hubListener {

    resource function failedmessage(http:Caller caller,
        http:Request req) returns error? {
        string subscriberSignatureValue = "";


        if (req.hasHeader(SUBSCRIBER_SIGNATURE_HEADER)) {
            subscriberSignatureValue = req.getHeader(SUBSCRIBER_SIGNATURE_HEADER);
        }
        string? topic=req.getQueryParamValue(TOPIC);
        string? callback=req.getQueryParamValue(CALLBACK);
        string? timestamp=req.getQueryParamValue(TIMESTAMP);
        string? messageCount=req.getQueryParamValue(MESSAGECOUNT);
        int|error messageCountValue= 'int:fromString(<string>messageCount);
        string topicParameter="";
        string callbackParameter="";
        string timestampParameter="";
        int messageCountParameter=config:getAsInt("mosip.hub.message_count_default",10);
        if(topic is string && topic!= ""){
         topicParameter=<string>topic;
        }else{
            check caller->badRequest(TOPIC_EMPTY_ERROR_MESSAGE);
             return ();
        }
        if(callback is string && callback!= ""){
         callbackParameter=<string>callback;
        }else{
            check caller->badRequest(CALLBACK_EMPTY_ERROR_MESSAGE);
             return ();
        }
        if(timestamp is string && timestamp!= ""){
         timestampParameter=<string>timestamp;
         }else{
            check caller->badRequest(TIMESTAMP_EMPTY_ERROR_MESSAGE);
             return ();
        }
        if(messageCountValue is int){
         messageCountParameter= messageCountValue;
        }
        repository:FailedContentPullRespModel[]|error fp=hubServiceImpl.getFailedContent(subscriberSignatureValue,topicParameter , callbackParameter ,timestampParameter ,messageCountParameter);
        if(fp is repository:FailedContentPullRespModel[]){
        json|error j = json.constructFrom(fp);      
        if(j is json){
        check caller->respond(j);
        }
        }else{
        check caller->badRequest(fp.detail()?.message);    
        }
        
    }

}
