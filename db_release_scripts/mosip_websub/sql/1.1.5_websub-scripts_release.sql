-- -------------------------------------------------------------------------------------------------
-- Database Name	: mosip_websub
-- Release Version 	: 1.1.5
-- Purpose    		: Database Alter scripts for the release for ID Authentication DB.       
-- Create By   		: Ram Bhatt
-- Created Date		: Jan-2021
-- 
-- Modified Date        Modified By         Comments / Remarks
-- -------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
\c mosip_websub sysadmin

--------- ------------ALTER TABLE SCRIPT DEPLOYMENT ------------------------------------------------

ALTER TABLE websub.subscription ALTER COLUMN is_deleted SET NOT NULL;
ALTER TABLE websub.topic ALTER COLUMN is_deleted SET NOT NULL;

ALTER TABLE websub.subscription ALTER COLUMN is_deleted SET DEFAULT FALSE;
ALTER TABLE websub.topic ALTER COLUMN is_deleted SET DEFAULT FALSE;

-------------------------------------------------------------------------------------------------------


