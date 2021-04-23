-- -------------------------------------------------------------------------------------------------
-- Database Name: mosip_websub
-- Release Version 	: 1.1.5
-- Purpose    		: Revoking Database Alter deployement done for release in Websub DB.       
-- Create By   		: Ram Bhatt
-- Created Date		: Apr-2021
-- 
-- Modified Date        Modified By         Comments / Remarks
-- -------------------------------------------------------------------------------------------------

\c mosip_websub sysadmin


DROP TABLE websub.message_store;
DROP TABLE websub.message_delivery_success;
DROP TABLE websub.message_delivery_failed;

ALTER TABLE websub.subscription DROP COLUMN id;

ALTER TABLE websub.subscription ADD constraint pk_sub_id PRIMARY KEY (topic,callback);

ALTER TABLE websub.subscription ADD COLUMN is_active boolean NOT NULL;

----------------------------------------------------------------------------------------------------





