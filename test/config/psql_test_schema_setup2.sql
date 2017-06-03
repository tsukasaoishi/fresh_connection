-- part2 setup of the test schema, post data load

\o /dev/null
SELECT pg_catalog.setval('addresses_id_seq', 1, false);
SELECT pg_catalog.setval('tels_id_seq', 1, false);
SELECT pg_catalog.setval('users_id_seq', 1, false);
\o

ALTER TABLE ONLY addresses
  ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);

ALTER TABLE ONLY tels
  ADD CONSTRAINT tels_pkey PRIMARY KEY (id);

ALTER TABLE ONLY users
  ADD CONSTRAINT users_pkey PRIMARY KEY (id);

REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;
