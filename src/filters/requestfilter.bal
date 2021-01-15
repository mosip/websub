import ballerina/http;
import mosip/services;
import ballerina/log;



public type RequestFilter object {



    private services:HubServiceImpl hubServiceImpl;

     public function __init(services:HubServiceImpl hubServiceImpl){
        self.hubServiceImpl = hubServiceImpl;
    }
    *http:RequestFilter;

    public function filterRequest(http:Caller caller, http:Request request,
                        http:FilterContext context) returns boolean {

        if(request.getQueryParamValue("hub.mode")=="publish"){
                       if(request.getContentType()=="application/json"){
             json|http:ClientError? payload = request.getJsonPayload();
             if(payload is json){
                log:printInfo("Message received at hub"); 
                 string msg=payload.toJsonString();
                 self.hubServiceImpl.onMessageReceived(request.getQueryParamValue("hub.topic").toString(),msg);
             }
            }
        }
       

        return true;
    }
};