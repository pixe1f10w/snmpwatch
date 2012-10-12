--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: sandbox; Type: SCHEMA; Schema: -; Owner: zabbix
--

CREATE SCHEMA sandbox;


ALTER SCHEMA sandbox OWNER TO zabbix;

SET search_path = sandbox, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: watched_items; Type: TABLE; Schema: sandbox; Owner: zabbix; Tablespace: 
--

CREATE TABLE watched_items (
    id bigint NOT NULL,
    hostid bigint NOT NULL,
    itemid bigint NOT NULL,
    wtf character varying(300)
);


ALTER TABLE sandbox.watched_items OWNER TO zabbix;

--
-- Name: history_id_seq; Type: SEQUENCE; Schema: sandbox; Owner: zabbix
--

CREATE SEQUENCE history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sandbox.history_id_seq OWNER TO zabbix;

--
-- Name: history_id_seq; Type: SEQUENCE OWNED BY; Schema: sandbox; Owner: zabbix
--

ALTER SEQUENCE history_id_seq OWNED BY watched_items.id;


--
-- Name: history; Type: TABLE; Schema: sandbox; Owner: zabbix; Tablespace: 
--

CREATE TABLE history (
    id bigint DEFAULT nextval('history_id_seq'::regclass) NOT NULL,
    watchedid bigint NOT NULL,
    dt date DEFAULT ('now'::text)::date NOT NULL,
    accumulate bigint NOT NULL,
    current bigint NOT NULL
);


ALTER TABLE sandbox.history OWNER TO zabbix;

--
-- Name: watched_items_id_seq; Type: SEQUENCE; Schema: sandbox; Owner: zabbix
--

CREATE SEQUENCE watched_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sandbox.watched_items_id_seq OWNER TO zabbix;

--
-- Name: watched_items_id_seq; Type: SEQUENCE OWNED BY; Schema: sandbox; Owner: zabbix
--

ALTER SEQUENCE watched_items_id_seq OWNED BY watched_items.id;


--
-- Name: id; Type: DEFAULT; Schema: sandbox; Owner: zabbix
--

ALTER TABLE watched_items ALTER COLUMN id SET DEFAULT nextval('watched_items_id_seq'::regclass);


--
-- Name: history_pk; Type: CONSTRAINT; Schema: sandbox; Owner: zabbix; Tablespace: 
--

ALTER TABLE ONLY history
    ADD CONSTRAINT history_pk PRIMARY KEY (id);


--
-- Name: history_watchedid_dt_key; Type: CONSTRAINT; Schema: sandbox; Owner: zabbix; Tablespace: 
--

ALTER TABLE ONLY history
    ADD CONSTRAINT history_watchedid_dt_key UNIQUE (watchedid, dt);


--
-- Name: watched_items_pk; Type: CONSTRAINT; Schema: sandbox; Owner: zabbix; Tablespace: 
--

ALTER TABLE ONLY watched_items
    ADD CONSTRAINT watched_items_pk PRIMARY KEY (id);


--
-- Name: history_watched_fk; Type: FK CONSTRAINT; Schema: sandbox; Owner: zabbix
--

ALTER TABLE ONLY history
    ADD CONSTRAINT history_watched_fk FOREIGN KEY (watchedid) REFERENCES watched_items(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: watched_items_hosts_fk; Type: FK CONSTRAINT; Schema: sandbox; Owner: zabbix
--

ALTER TABLE ONLY watched_items
    ADD CONSTRAINT watched_items_hosts_fk FOREIGN KEY (hostid) REFERENCES public.hosts(hostid) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: watched_items_items_fk; Type: FK CONSTRAINT; Schema: sandbox; Owner: zabbix
--

ALTER TABLE ONLY watched_items
    ADD CONSTRAINT watched_items_items_fk FOREIGN KEY (itemid) REFERENCES public.items(itemid) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

