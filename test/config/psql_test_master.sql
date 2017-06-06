-- create the master data set
\echo Setting up master data set

\ir psql_test_schema_setup1.sql

COPY addresses (id, user_id, prefecture, created_at, updated_at) FROM stdin;
1	1	Tokyo (master)	2014-04-10 07:24:16	2014-04-10 07:24:16
\.

COPY tels (id, user_id, number, created_at, updated_at) FROM stdin;
1	1	03-1111-1111 (master)	2014-04-10 07:24:16	2014-04-10 07:24:16
2	1	03-1111-1112 (master)	2014-04-10 07:24:16	2014-04-10 07:24:16
3	1	03-1111-1113 (master)	2014-04-10 07:24:16	2014-04-10 07:24:16
\.

COPY users (id, name, created_at, updated_at) FROM stdin;
1	Tsukasa (master)	2014-04-10 07:24:16	2014-04-10 07:24:16
2	Other	2014-04-10 07:24:16	2014-04-10 07:24:16
\.

\ir psql_test_schema_setup2.sql
