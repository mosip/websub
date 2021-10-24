import ballerina/http;
import ballerina/log;
import mosip/services;



public type RequestFilter object {



    private services:HubServiceImpl hubServiceImpl;

    public function __init(services:HubServiceImpl hubServiceImpl) {
        self.hubServiceImpl = hubServiceImpl;
    }
    *http:RequestFilter;

    public function filterRequest(http:Caller caller, http:Request request,
        http:FilterContext context) returns boolean {

        if (request.getQueryParamValue("hub.mode") == "publish") {
            if (request.getContentType().indexOf("application/json", 0) is int) {
                json|http:ClientError? payload = request.getJsonPayload();
                if (payload is json) {
                    log:printInfo("Message received at hub");
                    string msg = payload.toJsonString();
                    self.hubServiceImpl.onMessageReceived(request.getQueryParamValue("hub.topic").toString(), msg);
                }
            } else {
                var resp = caller->badRequest(CONTENT_TYPE_ERROR.toString());
                if (resp is error) {
                    log:printError("Error sending response", err = resp);
                }
                return false;
            }
        }


        return true;
    }
};
