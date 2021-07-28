-- -------------------------------------------------------------------------------------------------
-- Database Name: mosip_websub
-- Release Version 	: 1.2
-- Purpose    		: Database Alter scripts for the release for Websub DB.       
-- Create By   		: Ram Bhatt
-- Created Date		: Jul-2021
-- 
-- Modified Date        Modified By         Comments / Remarks
-- -------------------------------------------------------------------------------------------------
-- Jul-2021		Ram Bhatt	    Size limit removed from message column
-----------------------------------------------------------------------------------------------------

\c mosip_websub sysadmin

-----------------------------------------------------------------------------------------------------
ALTER TABLE websub.message_store ALTER COLUMN message TYPE character varying;
-----------------------------------------------------------------------------------------------------

\ir ../ddl/websub-subscription_history.sql

ALTER TABLE websub.subscription_history ADD CONSTRAINT UNIQUE (topic, callback);

---------------------------------------------------------------------------------------------------
