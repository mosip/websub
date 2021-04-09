-- -------------------------------------------------------------------------------------------------
-- Database Name: mosip_websub
-- Table Name 	: websub.subscription
-- Purpose    	: Subscription: Stores list of subscriptions in the websub module, These subscription used to consume the message in websub module
--           
-- Create By   	: Sadanandegowda DM
-- Created Date	: Oct-2020
-- 
-- Modified Date        Modified By         Comments / Remarks
-- ------------------------------------------------------------------------------------------
-- Apr-2021	        Ram Bhatt           Primary Key changed to id from topic and callback
-- Apr-2021	        Ram Bhatt           Dropped is_active column
-- ------------------------------------------------------------------------------------------

-- object: websub.subscription | type: TABLE --
-- DROP TABLE IF EXISTS websub.subscription CASCADE;
CREATE TABLE websub.subscription (
	id character varying(36) NOT NULL,
	topic character varying(256),
	callback character varying(256),
	secret character varying(256),
	lease_seconds bigint,
	created_at bigint,
	cr_by character varying(256) NOT NULL,
	cr_dtimes timestamp NOT NULL,
	upd_by character varying(256),
	upd_dtimes timestamp,
	is_deleted boolean,
	del_dtimes timestamp,
	CONSTRAINT subscription_pk PRIMARY KEY (id)

);
-- ddl-end --
COMMENT ON TABLE websub.subscription IS 'Subscription: Stores list of subscriptions in the websub module, These subscription used to consume the message in websub module';
-- ddl-end --
COMMENT ON COLUMN websub.subscription.topic IS 'Topic: Topic for which subscription is done';
-- ddl-end --
COMMENT ON COLUMN websub.subscription.callback IS 'Call Back URL: Call back url used by the subscribers';
-- ddl-end --
COMMENT ON COLUMN websub.subscription.secret IS 'Secret Key: Secret key assigned for subscribers';
-- ddl-end --
COMMENT ON COLUMN websub.subscription.lease_seconds IS 'Lease Seconds: Lease seconds used by subscribers';
-- ddl-end --
COMMENT ON COLUMN websub.subscription.created_at IS 'Created At: Subscription created date time.';
-- ddl-end --
COMMENT ON COLUMN websub.subscription.cr_by IS 'Created By : ID or name of the user who create / insert record.';
-- ddl-end --
COMMENT ON COLUMN websub.subscription.cr_dtimes IS 'Created DateTimestamp : Date and Timestamp when the record is created/inserted';
-- ddl-end --
COMMENT ON COLUMN websub.subscription.upd_by IS 'Updated By : ID or name of the user who update the record with new values';
-- ddl-end --
COMMENT ON COLUMN websub.subscription.upd_dtimes IS 'Updated DateTimestamp : Date and Timestamp when any of the fields in the record is updated with new values.';
-- ddl-end --
COMMENT ON COLUMN websub.subscription.is_deleted IS 'IS_Deleted : Flag to mark whether the record is Soft deleted.';
-- ddl-end --
COMMENT ON COLUMN websub.subscription.del_dtimes IS 'Deleted DateTimestamp : Date and Timestamp when the record is soft deleted with is_deleted=TRUE';
-- ddl-end --
