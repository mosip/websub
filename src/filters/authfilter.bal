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
        string rolePrefix = "";
        string? partnerID = ();
        map<string>|error formParams = request.getFormParams();
        if (request.getQueryParamValue(MODE) == "publish") {
            string? topic = request.getQueryParamValue(TOPIC);
            if (topic is string) {
                int? idEndIndex = topic.indexOf("/", 0);
                if (idEndIndex is int) {
                    partnerID = topic.substring(0, idEndIndex);
                    rolePrefix = PUBLISH_ROLE_PREFIX + topic.substring(idEndIndex + 1, topic.length());
                } else {
                    rolePrefix = PUBLISH_ROLE_PREFIX + topic;
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
                        rolePrefix = prefix + topicDecoded.substring(idEndIndex + 1, topicDecoded.length());
                    } else {
                        rolePrefix = prefix + topicDecoded;
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

        string? authTokenTemp = authCookie[0].value;
        if (!(authTokenTemp is string)) {
            errorsResponse.statusCode = 401;
            errorsResponse.setPayload("Authentication token parsing error");
            var result = caller->respond(errorsResponse);
            handleError(result);
            return false;
        }
        string authToken = <string>authTokenTemp;
        http:Request req = new;
        req.addHeader("Cookie", "Authorization=".concat(authToken));
        var responseTemp = self.clientEndpoint->get(config:getAsString("mosip.auth.validate_token_url"), req);
        if (!(responseTemp is http:Response)) {
            errorsResponse.statusCode = 500;
            error err = <error>responseTemp;
            errorsResponse.setPayload("Error calling auth server " + err.reason());
            var result = caller->respond(errorsResponse);
            handleError(result);
            return false;
        }
        http:Response response = <http:Response>responseTemp;

        int statusCode = response.statusCode;
        if (statusCode != 200) {
            errorsResponse.statusCode = statusCode;
            json|http:ClientError responseJsonTemp = <map<json>>response.getJsonPayload();
            if (responseJsonTemp is json) {
                map<json> res = <map<json>>responseJsonTemp;
                json[] errArray = <json[]>res["errors"];
                map<json> err = <map<json>>errArray[0];
                errorsResponse.setPayload(<@untained>("Error in auth service " + err["message"].toString()));
            } else {
                http:ClientError err = <http:ClientError>responseJsonTemp;
                errorsResponse.setPayload(<@untained>("Error in auth service " + err.reason()));
            }
            var result = caller->respond(errorsResponse);
            handleError(result);
            return false;
        }

        json|http:ClientError responseJsonTemp = response.getJsonPayload();
        if (!(responseJsonTemp is json)) {
            errorsResponse.statusCode = 500;
            errorsResponse.setPayload(<@untained>("Error in auth server " + responseJsonTemp.reason()));
            var result = caller->respond(errorsResponse);
            handleError(result);
            return false;
        }
        json responseJson = <json>responseJsonTemp;
        map<json> resWrapper = <map<json>>responseJson;
        if (!(resWrapper["errors"] is ())) {
            json[] errArray = <json[]>resWrapper["errors"];
            map<json> err = <map<json>>errArray[0];
            errorsResponse.statusCode = 200;
            errorsResponse.setPayload(<@untained>("Internal errors in auth service " + err["message"].toString()));
            var result = caller->respond(errorsResponse);
            handleError(result);
            return false;
        }

        map<json> res = <map<json>>resWrapper["response"];
        string roles = res["role"].toString();
        string[] rolesArray = stringutils:split(roles, ",");

        if (rolePrefix.indexOf(PUBLISH_ROLE_PREFIX, 0) is int) {
            return isPublisherAuthorized(partnerID, rolePrefix, rolesArray, caller);
        } else {
            return isSubscriberAuthorized(partnerID, rolePrefix, rolesArray, res["userId"].toString(), caller);
        }

    }
};

function handleError(error? result) {
    if (result is error) {
        log:printError(result.detail().toString());
    }
}

function isPublisherAuthorized(string? partnerID, string rolePrefix, string[] rolesArray, http:Caller caller) returns boolean {
    string roleTemp = "";
    if (partnerID is string) {
        roleTemp = rolePrefix.concat(All_INDIVIDUAL_SUFFIX);
    } else {
        roleTemp = rolePrefix.concat(GENERAL_SUFFIX);
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

function isSubscriberAuthorized(string? partnerID, string rolePrefix, string[] rolesArray, string authPartnerID, http:Caller caller) returns boolean {
    string roleTemp = "";
    if (partnerID is string) {
        roleTemp = rolePrefix.concat(INDIVIDUAL_SUFFIX);

        int i = 0;
        while (i < rolesArray.length()) {
            if (rolesArray[i] == roleTemp && authPartnerID == partnerID) {
                return true;
            }
            i = i + 1;
        }
    } else {
        roleTemp = rolePrefix.concat(GENERAL_SUFFIX);
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
