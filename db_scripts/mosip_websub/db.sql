DROP DATABASE IF EXISTS mosip_websub;
CREATE DATABASE mosip_websub
	ENCODING = 'UTF8'
	LC_COLLATE = 'en_US.UTF-8'
	LC_CTYPE = 'en_US.UTF-8'
	TABLESPACE = pg_default
	OWNER = sysadmin
	TEMPLATE  = template0;
-- ddl-end --
COMMENT ON DATABASE mosip_websub IS 'The data related to Web Sub Hub flows and transaction will be maintained in this database. This database also maintains data that is needed to message transfer.';
-- ddl-end --

\c mosip_websub sysadmin

-- object: websub | type: SCHEMA --
DROP SCHEMA IF EXISTS websub CASCADE;
CREATE SCHEMA websub;
-- ddl-end --
ALTER SCHEMA websub OWNER TO sysadmin;
-- ddl-end --

ALTER DATABASE mosip_websub SET search_path TO websub,pg_catalog,public;
-- ddl-end --

-- REVOKECONNECT ON DATABASE mosip_websub FROM PUBLIC;
-- REVOKEALL ON SCHEMA websub FROM PUBLIC;
-- REVOKEALL ON ALL TABLES IN SCHEMA websub FROM PUBLIC ;
