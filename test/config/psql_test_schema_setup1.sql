-- create the schema (part 1)

\set QUIET 1
\timing off

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

DROP TABLE IF EXISTS addresses CASCADE;
DROP TABLE IF EXISTS tels      CASCADE;
DROP TABLE IF EXISTS users     CASCADE;

CREATE TABLE addresses (
  id integer NOT NULL,
  user_id integer DEFAULT 0 NOT NULL,
  prefecture character varying DEFAULT ''::character varying NOT NULL,
  created_at timestamp without time zone NOT NULL,
  updated_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE addresses_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

ALTER SEQUENCE addresses_id_seq OWNED BY addresses.id;

CREATE TABLE tels (
  id integer NOT NULL,
  user_id integer DEFAULT 0 NOT NULL,
  number character varying DEFAULT ''::character varying NOT NULL,
  created_at timestamp without time zone NOT NULL,
  updated_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE tels_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

ALTER SEQUENCE tels_id_seq OWNED BY tels.id;

CREATE TABLE users (
  id integer NOT NULL,
  name character varying DEFAULT ''::character varying NOT NULL,
  created_at timestamp without time zone NOT NULL,
  updated_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE users_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

ALTER SEQUENCE users_id_seq OWNED BY users.id;

ALTER TABLE ONLY addresses ALTER COLUMN id SET DEFAULT nextval('addresses_id_seq'::regclass);

ALTER TABLE ONLY tels ALTER COLUMN id SET DEFAULT nextval('tels_id_seq'::regclass);

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);
