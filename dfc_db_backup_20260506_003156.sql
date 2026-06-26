--
-- PostgreSQL database dump
--

-- Dumped from database version 15.4 (Debian 15.4-1.pgdg110+1)
-- Dumped by pg_dump version 15.4 (Debian 15.4-1.pgdg110+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: events; Type: TABLE; Schema: public; Owner: dfc_admin
--

CREATE TABLE public.events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    status character varying(50) DEFAULT 'scheduled'::character varying NOT NULL,
    processed boolean DEFAULT false,
    start_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.events OWNER TO dfc_admin;

--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: dfc_admin
--

COPY public.events (id, name, status, processed, start_at, created_at, updated_at) FROM stdin;
\.


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: dfc_admin
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

