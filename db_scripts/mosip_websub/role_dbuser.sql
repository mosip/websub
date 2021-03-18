-- object: websubuser | type: ROLE --
-- DROP ROLE IF EXISTS websubuser;
CREATE ROLE websubuser WITH 
	INHERIT
	LOGIN
	PASSWORD :dbuserpwd;
-- ddl-end --
