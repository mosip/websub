import ballerina/config;
import ballerina/http;
import ballerina/log;
import ballerina/stringutils;
import ballerina/encoding;



public type AuthFilter object {

    private http:Client clientEndpoint;

    public function __init() {
        self.clientEndpoint = new (config:getAsString("mosip.auth.base_url"));
    }
    *http:RequestFilter;

    public function filterRequest(http:Caller caller, http:Request request,
        http:FilterContext context) returns boolean {
        if (config:getAsString("mosip.auth.filter_status", "disable") == "enable") {
            string topic="";
            map<string>|error formParams = request.getFormParams();
            string? topicParam=request.getQueryParamValue("hub.topic");
            if(formParams is map<string>){
            string|error topicDecoded =  encoding:decodeUriComponent(formParams.get("hub.topic"), "UTF-8");
            if(topicDecoded is string){
                topic=topicDecoded;
            }
            }else if(topicParam is string){
            topic=topicParam;
            }
            http:Response errorsResponse = new;
            http:Cookie[] cookies = request.getCookies();
            if (cookies.length() < 0) {
                errorsResponse.statusCode = 401;
                errorsResponse.setPayload("Authentication token required");
                var result = caller->respond(errorsResponse);
                handleError(result);
                return false;
            }
            http:Cookie[] authCookie = cookies.filter(function
                (http:Cookie cookie) returns boolean {
                return cookie.name == "Authorization";
            });
            if (authCookie.length() > 0) {
                string? authToken = authCookie[0].value;
                if (authToken is string) {
                    http:Request req = new;
                    req.addHeader("Cookie", "Authorization=".concat(authToken));
                    var response = self.clientEndpoint->get(config:getAsString("mosip.auth.validate_token_url"), req);
                    if (response is http:Response)
                    {
                        int statusCode = response.statusCode;
                        if (statusCode == 200) {
                            json|http:ClientError responseJson = response.getJsonPayload();
                            if (responseJson is json) {
                                map<json> resWrapper = <map<json>>responseJson;
                                if (resWrapper["errors"] is ()) {
                                    map<json> res = <map<json>>resWrapper["response"];
                                    // for now we will be adding topics as roles because authservice doesnot returns scopes. Later we will add topic as a scope.
                                    string roles = res["role"].toString();
                                    log:printInfo(roles);
                                    string[] rolesArray = stringutils:split(roles, ",");
                                    int i = 0;
                                    while (i < rolesArray.length()) {
                                        log:printInfo(rolesArray[i]);
                                        log:printInfo(topic);
                                        if (rolesArray[i] == topic) {
                                            return true;
                                        }
                                        i = i + 1;
                                    }
                                    errorsResponse.statusCode = 403;
                                    errorsResponse.setPayload("Subject does not have access for this topic");
                                    var result = caller->respond(errorsResponse);
                                    handleError(result);
                                    return false;
                                } else {
                                    map<json> errors = <map<json>>resWrapper["errors"];
                                    errorsResponse.statusCode = 401;
                                    errorsResponse.setPayload("Subject does not have access for this topic");
                                    var result = caller->respond(errorsResponse);
                                    handleError(result);
                                    return false;
                                }
                            }
                        }
                        else {
                            errorsResponse.statusCode = 500;
                            errorsResponse.setPayload("Error in auth server");
                            var result = caller->respond(errorsResponse);
                            handleError(result);
                            return false;
                        }
                    } else {
                        errorsResponse.statusCode = 500;
                        errorsResponse.setPayload("Error calling auth server");
                        var result = caller->respond(errorsResponse);
                        handleError(result);
                        return false;
                    }
                } else {
                    errorsResponse.statusCode = 401;
                    errorsResponse.setPayload("Authentication token parsing error");
                    var result = caller->respond(errorsResponse);
                    handleError(result);
                    return false;
                }


            }else {
                    errorsResponse.statusCode = 401;
                    errorsResponse.setPayload("Authentication token required");
                    var result = caller->respond(errorsResponse);
                    handleError(result);
                    return false;
                }


            return false;
        } else {
            return true;
        }
    }
};

function handleError(error? result) {
    if (result is error) {
        log:printError(result.detail().toString());
    }
}


