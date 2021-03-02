public type ServiceError record {
    string errorCode;
    string message;
};

public type TokenValidationResponse record {
    string mobile;
    string mail;
    string langCode;
    string userPassword;
    string name;
    string role;
    string token;
    string rid;
};

public type ResponseWrapper record {
    string id;
    string responsetime;
    any metadata;
    TokenValidationResponse response;
    ServiceError[] errors;
};
