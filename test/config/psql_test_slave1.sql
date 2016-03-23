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


ALTER TABLE users_id_seq OWNER TO tsukasa;

ALTER SEQUENCE users_id_seq OWNED BY users.id;

ALTER TABLE ONLY addresses ALTER COLUMN id SET DEFAULT nextval('addresses_id_seq'::regclass);

ALTER TABLE ONLY tels ALTER COLUMN id SET DEFAULT nextval('tels_id_seq'::regclass);

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);

COPY addresses (id, user_id, prefecture, created_at, updated_at) FROM stdin;
1	1	Tokyo (slave1)	2014-04-10 07:24:16	2014-04-10 07:24:16
\.

SELECT pg_catalog.setval('addresses_id_seq', 1, false);

COPY tels (id, user_id, number, created_at, updated_at) FROM stdin;
1	1	03-1111-1111 (slave1)	2014-04-10 07:24:16	2014-04-10 07:24:16
2	1	03-1111-1112 (slave1)	2014-04-10 07:24:16	2014-04-10 07:24:16
3	1	03-1111-1113 (slave1)	2014-04-10 07:24:16	2014-04-10 07:24:16
\.

SELECT pg_catalog.setval('tels_id_seq', 1, false);

COPY users (id, name, created_at, updated_at) FROM stdin;
1	Tsukasa (slave1)	2014-04-10 07:24:16	2014-04-10 07:24:16
2	Other	2014-04-10 07:24:16	2014-04-10 07:24:16
3	Other	2014-04-10 07:24:16	2014-04-10 07:24:16
\.

SELECT pg_catalog.setval('users_id_seq', 1, false);

ALTER TABLE ONLY addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);

ALTER TABLE ONLY tels
    ADD CONSTRAINT tels_pkey PRIMARY KEY (id);

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM tsukasa;
GRANT ALL ON SCHEMA public TO tsukasa;
GRANT ALL ON SCHEMA public TO PUBLIC;
