const string CREATE_TOPICS_TABLE = "CREATE TABLE IF NOT EXISTS topics (topic VARCHAR(255), PRIMARY KEY (topic))";

const string INSERT_INTO_TOPICS = "INSERT INTO topics (topic) VALUES (?)";
const string DELETE_FROM_TOPICS = "DELETE FROM topics WHERE topic=?";
const string SELECT_ALL_FROM_TOPICS = "SELECT * FROM topics";

const string CREATE_SUBSCRIPTIONS_TABLE = "CREATE TABLE IF NOT EXISTS subscriptions(topic VARCHAR(255), callback VARCHAR(255), secret VARCHAR(255),lease_seconds BIGINT, created_at BIGINT, PRIMARY KEY (topic, callback))";
const string INSERT_INTO_SUBSCRIPTIONS_TABLE = "INSERT INTO subscriptions (topic,callback,secret,lease_seconds,created_at) VALUES (?,?,?,?,?)";
const string DELETE_FROM_SUBSCRIPTIONS = "DELETE FROM subscriptions WHERE topic=? AND callback=?";
const string SELECT_FROM_SUBSCRIPTIONS = "SELECT topic, callback, secret, lease_seconds, created_at FROM subscriptions";