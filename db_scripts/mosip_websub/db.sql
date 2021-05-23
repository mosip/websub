CREATE DATABASE mosip_websub
	ENCODING = 'UTF8'
	LC_COLLATE = 'en_US.UTF-8'
	LC_CTYPE = 'en_US.UTF-8'
	TABLESPACE = pg_default
	OWNER = postgres
	TEMPLATE  = template0;
COMMENT ON DATABASE mosip_websub IS 'The data related to Web Sub Hub flows and transaction will be maintained in this database. This database also maintains data that is needed to message transfer.';

\c mosip_websub 

DROP SCHEMA IF EXISTS websub CASCADE;
CREATE SCHEMA websub;
ALTER SCHEMA websub OWNER TO postgres;

ALTER DATABASE mosip_websub SET search_path TO websub,pg_catalog,public;
