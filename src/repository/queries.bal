const string INSERT_INTO_TOPICS = "INSERT INTO topic (topic,cr_by,cr_dtimes,upd_by,upd_dtimes,is_deleted,del_dtimes) VALUES (?,?,?,?,?,?,?)";
const string DELETE_FROM_TOPICS = "UPDATE topic SET is_deleted = 'TRUE',upd_by=?,upd_dtimes=?,del_dtimes=? WHERE topic=?";
const string SELECT_ALL_FROM_TOPICS = "SELECT topic FROM topic where NOT is_deleted";

const string INSERT_INTO_SUBSCRIPTIONS_TABLE = "INSERT INTO subscription (topic,callback,secret,lease_seconds,created_at,is_active,cr_by,cr_dtimes,upd_by,upd_dtimes,is_deleted,del_dtimes) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)";
const string HARD_DELETE_FROM_SUBSCRIPTIONS = "DELETE FROM subscription  WHERE topic=? AND callback=?";
const string SOFT_DELETE_FROM_SUBSCRIPTIONS = "UPDATE subscription SET is_active = 'FALSE',upd_by=?,upd_dtimes=? WHERE topic=? AND callback=?";
const string SELECT_FROM_SUBSCRIPTIONS = "SELECT topic, callback, secret, lease_seconds, created_at FROM subscription where is_active";
