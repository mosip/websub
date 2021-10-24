-- -------------------------------------------------------------------------------------------------
-- Database Name: mosip_websub
-- Release Version 	: 1.1.5
-- Purpose    		: Database Alter scripts for the release for Websub DB.       
-- Create By   		: Ram Bhatt
-- Created Date		: Apr-2021
-- 
-- Modified Date        Modified By         Comments / Remarks
-- -------------------------------------------------------------------------------------------------

\c mosip_websub sysadmin


\ir ddl/websub-message_store.sql
\ir ddl/websub-message_delivery_success.sql
\ir ddl/websub-message_delivery_failed.sql



--ALTER TABLE websub.subscription DROP constraint pk_sub_id;

ALTER TABLE websub.subscription ADD COLUMN id character varying(36);

--ALTER TABLE websub.subscription ADD constraint subscription_pk PRIMARY KEY (id);

ALTER TABLE websub.subscription DROP COLUMN is_active;

---------------------------------------------------------------------------------------------------
