import ballerina/http;
import mosip/repository;
import ballerina/lang.'int;
import ballerina/config;

@http:ServiceConfig {
    basePath: "/sync"
}
service failedcontentpull on hubListener {

    resource function failedmessage(http:Caller caller,
        http:Request req) returns error? {
        string subscriberSignatureValue = "";


        if (req.hasHeader("X-Subscriber-Signature")) {
            subscriberSignatureValue = req.getHeader("X-Subscriber-Signature");
        }
        string? topic=req.getQueryParamValue("topic");
        string? callback=req.getQueryParamValue("callback");
        string? timestamp=req.getQueryParamValue("timestamp");
        string? messageCount=req.getQueryParamValue("messageCount");
        int|error messageCountValue= 'int:fromString(<string>messageCount);
        string topicParameter="";
        string callbackParameter="";
        string timestampParameter="";
        int messageCountParameter=config:getAsInt("mosip.hub.message_count_default",10);
        if(topic is string){
         topicParameter=<string>topic;
        }
        if(callback is string){
         callbackParameter=<string>callback;
        }
        if(timestamp is string){
         timestampParameter=<string>timestamp;
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
