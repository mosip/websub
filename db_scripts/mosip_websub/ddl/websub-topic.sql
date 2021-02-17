-- -------------------------------------------------------------------------------------------------
-- Database Name: mosip_websub
-- Table Name 	: websub.topic
-- Purpose    	: Topic: Stores list of topics used in websub modules, this topics are used by producers and subscribers for message transfer.
--           
-- Create By   	: Sadanandegowda DM
-- Created Date	: Oct-2020
-- 
-- Modified Date        Modified By         Comments / Remarks
-- ------------------------------------------------------------------------------------------
-- Jan-2021		Ram Bhatt	    Set is_deleted flag to not null and default false     
-- ------------------------------------------------------------------------------------------

-- object: websub.topic | type: TABLE --
-- DROP TABLE IF EXISTS websub.topic CASCADE;
CREATE TABLE websub.topic(
	topic character varying(256) NOT NULL,
	cr_by character varying(256) NOT NULL,
	cr_dtimes timestamp NOT NULL,
	upd_by character varying(256),
	upd_dtimes timestamp,
	is_deleted boolean NOT NULL DEFAULT FALSE,
	del_dtimes timestamp,
	CONSTRAINT pk_topic PRIMARY KEY (topic)

);
-- ddl-end --
COMMENT ON TABLE websub.topic IS 'Topic: Stores list of topics used in websub modules, this topics are used by producers and subscribers for message transfer.';
-- ddl-end --
COMMENT ON COLUMN websub.topic.topic IS 'Topic: Name of the topic created for message transfer';
-- ddl-end --
COMMENT ON COLUMN websub.topic.cr_by IS 'Created By : ID or name of the user who create / insert record.';
-- ddl-end --
COMMENT ON COLUMN websub.topic.cr_dtimes IS 'Created DateTimestamp : Date and Timestamp when the record is created/inserted';
-- ddl-end --
COMMENT ON COLUMN websub.topic.upd_by IS 'Updated By : ID or name of the user who update the record with new values';
-- ddl-end --
COMMENT ON COLUMN websub.topic.upd_dtimes IS 'Updated DateTimestamp : Date and Timestamp when any of the fields in the record is updated with new values.';
-- ddl-end --
COMMENT ON COLUMN websub.topic.is_deleted IS 'IS_Deleted : Flag to mark whether the record is Soft deleted.';
-- ddl-end --
COMMENT ON COLUMN websub.topic.del_dtimes IS 'Deleted DateTimestamp : Date and Timestamp when the record is soft deleted with is_deleted=TRUE';
-- ddl-end --
