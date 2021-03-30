import ballerina/crypto;
#SHA 256 of input provided to this funtion 
# + input - Input to be converted to hash.
# + return - The hash `string` converted to base64.
public function hashSha256(string input) returns string {
    return crypto:hashSha256(input.toBytes()).toBase64();
}

public function hmacSha256(string input,string key) returns string {
    return crypto:hmacSha256(input.toBytes(), key.toBytes()).toBase64();
}




