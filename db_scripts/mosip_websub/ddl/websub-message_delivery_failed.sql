-- -------------------------------------------------------------------------------------------------
-- Database Name: mosip_websub
-- Table Name 	: websub.message_delivery_failed
-- Purpose    	: Stores list of messages which have failed to deliver.
--           
-- Create By   	: Ram Bhatt
-- Created Date	: Apr-2021
-- 
-- Modified Date        Modified By         Comments / Remarks
-- ------------------------------------------------------------------------------------------
-- 
-- ------------------------------------------------------------------------------------------

-- object: websub.message_delivery_failed | type: TABLE --
-- DROP TABLE IF EXISTS websub.message_delivery_failed CASCADE;
CREATE TABLE websub.message_delivery_failed (
	msg_id character varying(36) NOT NULL,
	subscription_id character varying(36) NOT NULL,
	delivery_failed_dtimes timestamp NOT NULL,
	last_fetch_dtimes timestamp,
	delivery_failure_reason character varying(128),
	delivery_failure_error character varying(128),
	cr_by character varying(256) NOT NULL,
	cr_dtimes timestamp NOT NULL,
	upd_by character varying(256),
	upd_dtimes timestamp,
	is_deleted boolean,
	del_dtimes timestamp,
	CONSTRAINT message_delivery_failed_pk PRIMARY KEY (msg_id,subscription_id)

);
-- ddl-end --



