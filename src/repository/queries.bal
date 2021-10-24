const string INSERT_INTO_TOPICS = "INSERT INTO websub.topic (topic,cr_by,cr_dtimes,upd_by,upd_dtimes,is_deleted,del_dtimes) VALUES (?,?,?,?,?,?,?)";
const string DELETE_FROM_TOPICS = "UPDATE websub.topic SET is_deleted = 'TRUE',upd_by=?,upd_dtimes=?,del_dtimes=? WHERE topic=?";
const string SELECT_ALL_FROM_TOPICS = "SELECT topic FROM websub.topic where NOT is_deleted";

const string INSERT_INTO_SUBSCRIPTIONS_TABLE = "INSERT INTO websub.subscription (id,topic,callback,secret,lease_seconds,created_at,cr_by,cr_dtimes,upd_by,upd_dtimes,is_deleted,del_dtimes) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)";
const string HARD_DELETE_FROM_SUBSCRIPTIONS = "DELETE FROM websub.subscription  WHERE topic=? AND callback=?";
const string SOFT_DELETE_FROM_SUBSCRIPTIONS = "UPDATE websub.subscription SET is_deleted = 'TRUE',upd_by=?,upd_dtimes=? WHERE topic=? AND callback=? AND is_deleted = 'FALSE'";
const string UPDATE_SUBSCRIPTIONS = "UPDATE websub.subscription SET topic=?, callback=?, secret=?, lease_seconds=?, created_at=?,upd_by=?,upd_dtimes=? WHERE id=? AND is_deleted = 'FALSE'";
const string SELECT_FROM_SUBSCRIPTIONS = "SELECT topic, callback, secret, lease_seconds, created_at FROM websub.subscription where is_deleted = 'FALSE'";
const string SELECT_FROM_SUBSCRIPTIONS_BY_TOPIC_CALLBACK = "SELECT id,topic, callback, secret, lease_seconds, created_at FROM websub.subscription where topic=? AND callback=? AND is_deleted = 'FALSE'";

const string INSERT_INTO_MESSAGE_TABLE = "INSERT INTO websub.message_store (id,message,topic,publisher,pub_dtimes,hub_instance_id,msg_topic_hash,cr_by,cr_dtimes,upd_by,upd_dtimes,is_deleted,del_dtimes) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)";
const string SELECT_FROM_MESSAGE_BY_TOPIC_MESSAGE = "SELECT id,message,topic,publisher,pub_dtimes,hub_instance_id,msg_topic_hash FROM websub.message_store where topic=? and message=?";
const string SELECT_FROM_MESSAGE_BY_HASH = "SELECT id,message,topic,publisher,pub_dtimes,hub_instance_id,msg_topic_hash FROM websub.message_store where msg_topic_hash=?";
const string SELECT_FROM_MESSAGE_BY_ID = "SELECT id,message,topic,publisher,pub_dtimes,hub_instance_id,msg_topic_hash FROM websub.message_store where id IN (?)";


const string INSERT_INTO_SUCCESS_DELIVERY_TABLE = "INSERT INTO websub.message_delivery_success (msg_id,subscription_id,delivery_success_dtimes,cr_by,cr_dtimes,upd_by,upd_dtimes,is_deleted,del_dtimes) VALUES (?,?,?,?,?,?,?,?,?)";

const string INSERT_INTO_FAILED_DELIVERY_TABLE = "INSERT INTO websub.message_delivery_failed (msg_id,subscription_id,delivery_failed_dtimes,delivery_failure_reason,delivery_failure_error,cr_by,cr_dtimes,upd_by,upd_dtimes,is_deleted,del_dtimes) VALUES (?,?,?,?,?,?,?,?,?,?,?)";
const string UPDATE_LAST_FETCH_TIMESTAMP_INTO_FAILED_DELIVERY_TABLE = "UPDATE websub.message_delivery_failed SET last_fetch_dtimes =?,upd_by=?,upd_dtimes=? WHERE msg_id=? AND subscription_id=? AND is_deleted = 'FALSE'";
const string DELETE_FROM_FAILED_DELIVERY_TABLE = "UPDATE websub.message_delivery_failed SET is_deleted = 'TRUE',upd_by=?,upd_dtimes=? WHERE msg_id=? AND subscription_id=? AND is_deleted = 'TRUE'";
const string SELECT_FROM_FAILED_DELIVERY_TABLE = "SELECT  msg_id,subscription_id,delivery_failed_dtimes,delivery_failure_reason,delivery_failure_error FROM websub.message_delivery_failed WHERE msg_id=? AND subscription_id=? AND is_deleted = 'FALSE'";
const string SELECT_AND_UPDATE_FROM_FAILED_DELIVERY_TABLE_BY_SUBID_AND_TIMESTAMP = "WITH c AS (SELECT msg_id FROM websub.message_delivery_failed WHERE subscription_id=? AND delivery_failed_dtimes>=? LIMIT  ?) UPDATE  websub.message_delivery_failed s SET last_fetch_dtimes=?,upd_by=?,upd_dtimes=? FROM c WHERE s.msg_id = c.msg_id RETURNING s.msg_id";
const string RESTART_REPUBLISH_MESSAGES = "SELECT message,topic FROM websub.message_store WHERE pub_dtimes >=? and id NOT IN (SELECT  msg_id FROM websub.message_delivery_failed WHERE delivery_failed_dtimes>=? UNION SELECT  msg_id FROM websub.message_delivery_success WHERE delivery_success_dtimes>=?)";
