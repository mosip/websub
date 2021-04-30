import ballerina/config;
import ballerina/encoding;
import ballerina/http;
import ballerina/log;
import ballerina/stringutils;



public type AuthFilter object {

    private http:Client clientEndpoint;

    public function __init() {
        self.clientEndpoint = new (config:getAsString("mosip.auth.base_url"));
    }
    *http:RequestFilter;

    public function filterRequest(http:Caller caller, http:Request request,
        http:FilterContext context) returns boolean {
        if (config:getAsBoolean("mosip.auth.filter_disable", false)) {
            return true;
        }
        string role = "";
        string? partnerID = ();
        map<string>|error formParams = request.getFormParams();
        if (request.getQueryParamValue(MODE) == "publish") {
            string? topic = request.getQueryParamValue(TOPIC);
            if (topic is string) {
                int? idEndIndex = topic.indexOf("/", 0);
                if (idEndIndex is int) {
                    partnerID = topic.substring(0, idEndIndex);
                    role = PUBLISH_ROLE_PREFIX + topic.substring(idEndIndex + 1, topic.length());
                } else {
                    role = PUBLISH_ROLE_PREFIX + topic;
                }

            }
        } else if (formParams is map<string>) {
            string|error topicDecoded = encoding:decodeUriComponent(formParams.get(TOPIC), "UTF-8");
            if (topicDecoded is string) {
                string? modeParam = formParams.get(MODE);
                string prefix = "";
                if (modeParam is string) {
                    if (modeParam == REGISTER || modeParam == UNREGISTER) {
                        prefix = PUBLISH_ROLE_PREFIX;
                    } else if (modeParam == SUBSCRIBE || modeParam == UNSUBSCRIBE) {
                        prefix = SUBSCRIBE_ROLE_PREFIX;
                    }

                    int? idEndIndex = topicDecoded.indexOf("/", 0);
                    if (idEndIndex is int) {
                        partnerID = topicDecoded.substring(0, idEndIndex);
                        role = prefix + topicDecoded.substring(idEndIndex + 1, topicDecoded.length());
                    } else {
                        role = prefix + topicDecoded;
                    }
                }
            }
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
        if (authCookie.length() <= 0) {
            errorsResponse.statusCode = 401;
            errorsResponse.setPayload("Authentication token required");
            var result = caller->respond(errorsResponse);
            handleError(result);
            return false;
        }

        string? authToken = authCookie[0].value;
        if (authToken is string) {
            http:Request req = new;
            req.addHeader("Cookie", "Authorization=".concat(authToken));
            var response = self.clientEndpoint->get(config:getAsString("mosip.auth.validate_token_url"), req);

            if (response is http:Response) {
                int statusCode = response.statusCode;
                if (statusCode != 200) {
                    errorsResponse.statusCode = statusCode;
                    errorsResponse.setPayload("Error in auth server " + response.toString());
                    var result = caller->respond(errorsResponse);
                    handleError(result);
                    return false;
                }

                json|http:ClientError responseJson = response.getJsonPayload();
                if (responseJson is json) {
                    map<json> resWrapper = <map<json>>responseJson;
                    if (!(resWrapper["errors"] is ())) {
                        map<json> errors = <map<json>>resWrapper["errors"];
                        errorsResponse.statusCode = 200;
                        errorsResponse.setPayload("Internal errors in auth service");
                        var result = caller->respond(errorsResponse);
                        handleError(result);
                        return false;
                    }

                    map<json> res = <map<json>>resWrapper["response"];
                    string roles = res["role"].toString();
                    string[] rolesArray = stringutils:split(roles, ",");

                    if (role.indexOf(PUBLISH_ROLE_PREFIX, 0) is int) {
                        return authorizePublisher(partnerID, role, rolesArray,caller);
                    } else {
                        return authorizeSubscriber(partnerID, role, rolesArray, res["userId"].toString(),caller);
                    }

                }
            } else {
                errorsResponse.statusCode = 500;
                errorsResponse.setPayload("Error calling auth server " + response.toString());
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
        return false;
    }
};

function handleError(error? result) {
    if (result is error) {
        log:printError(result.detail().toString());
    }
}

function authorizePublisher(string? partnerID, string role, string[] rolesArray,http:Caller caller) returns boolean {
    string roleTemp = "";
    if (partnerID is string) {
        roleTemp = role.concat(All_INDIVIDUAL_SUFFIX);
    } else {
        roleTemp = role.concat(GENERAL_SUFFIX);
    }
    int i = 0;
    while (i < rolesArray.length()) {
        if (rolesArray[i] == roleTemp) {
            return true;
        }
        i = i + 1;
    }
    http:Response errorsResponse = new;
    errorsResponse.statusCode = 403;
    errorsResponse.setPayload("Subject does not have access for this topic");
    var result = caller->respond(errorsResponse);
    handleError(result);
    return false;

}

function authorizeSubscriber(string? partnerID, string role, string[] rolesArray, string authPartnerID,http:Caller caller) returns boolean {
    string roleTemp = "";
    if (partnerID is string) {
        roleTemp = role.concat(INDIVIDUAL_SUFFIX);

        int i = 0;
        while (i < rolesArray.length()) {
            if (rolesArray[i] == roleTemp && authPartnerID == partnerID) {
                return true;
            }
            i = i + 1;
        }
    } else {
        roleTemp = role.concat(GENERAL_SUFFIX);
        int i = 0;
        while (i < rolesArray.length()) {
            if (rolesArray[i] == roleTemp) {
                return true;
            }
            i = i + 1;
        }
    }
    http:Response errorsResponse = new;
    errorsResponse.statusCode = 403;
    errorsResponse.setPayload("Subject does not have access for this topic");
    var result = caller->respond(errorsResponse);
    handleError(result);
    return false;
}
