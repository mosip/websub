-- -------------------------------------------------------------------------------------------------
-- Database Name: mosip_websub
-- Table Name 	: websub.message_delivery_success
-- Purpose    	: Stores status of successfully delivered messages.
--           
-- Create By   	: Ram Bhatt
-- Created Date	: Apr-2021
-- 
-- Modified Date        Modified By         Comments / Remarks
-- ------------------------------------------------------------------------------------------
-- 
-- ------------------------------------------------------------------------------------------
-- object: websub.message_delivery_success | type: TABLE --
-- DROP TABLE IF EXISTS websub.message_delivery_success CASCADE;
CREATE TABLE websub.message_delivery_success (
	msg_id character varying(36) NOT NULL,
	subscription_id character varying(36) NOT NULL,
	delivery_success_dtimes timestamp NOT NULL,
	cr_by character varying(256) NOT NULL,
	cr_dtimes timestamp NOT NULL,
	upd_by character varying(256),
	upd_dtimes timestamp,
	is_deleted boolean,
	del_dtimes timestamp,
	CONSTRAINT message_delivery_success_pk PRIMARY KEY (msg_id,subscription_id)

);
-- ddl-end --

