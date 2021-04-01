-- -------------------------------------------------------------------------------------------------
-- Database Name: mosip_websub
-- Table Name 	: websub.message_store
-- Purpose    	: Topic: Stores list of messages used in websub module.
--           
-- Create By   	: Ram Bhatt
-- Created Date	: Apr-2021
-- 
-- Modified Date        Modified By         Comments / Remarks
-- ------------------------------------------------------------------------------------------
-- 
-- ------------------------------------------------------------------------------------------

-- object: websub.message_store | type: TABLE --
-- DROP TABLE IF EXISTS websub.message_store CASCADE;
CREATE TABLE websub.message_store (
	id character varying(36) NOT NULL,
	message character varying(1024) NOT NULL,
	topic character varying(256) NOT NULL,
	publisher character varying(256),
	pub_dtimes timestamp NOT NULL,
	hub_instance_id character varying(36),
	msg_topic_hash character varying(64),
	cr_by character varying(256) NOT NULL,
	cr_dtimes timestamp NOT NULL,
	upd_by character varying(256),
	upd_dtimes timestamp,
	is_deleted boolean,
	del_dtimes timestamp,
	CONSTRAINT message_store_pk PRIMARY KEY (id)

);
-- ddl-end --


