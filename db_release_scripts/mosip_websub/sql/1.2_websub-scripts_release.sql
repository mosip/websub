-- -------------------------------------------------------------------------------------------------
-- Database Name: mosip_websub
-- Release Version 	: 1.1.5
-- Purpose    		: Database Alter scripts for the release for Websub DB.       
-- Create By   		: Ram Bhatt
-- Created Date		: Jul-2021
-- 
-- Modified Date        Modified By         Comments / Remarks
-- -------------------------------------------------------------------------------------------------

\c mosip_websub sysadmin


\ir ../ddl/websub-subscription_history.sql

ALTER TABLE websub.subscription_history ADD CONSTRAINT UNIQUE (topic, callback);

ALTER TABLE websub.subscription_history ALTER COLUMN lease_seconds TYPE bigint;

---------------------------------------------------------------------------------------------------
