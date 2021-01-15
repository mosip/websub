import ballerina/crypto;
#TODO: will add hmac
public function hashSha256(string input) returns string{
    return crypto:hashSha256(input.toBytes()).toBase64();
}