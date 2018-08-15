CREATE SEQUENCE public.roles_orgid_seq;
CREATE SEQUENCE public.users_iid_seq;
CREATE SEQUENCE public.users_pid_seq;

CREATE TABLE public.config_oauth2
(
    appid character varying(128) COLLATE pg_catalog."default" NOT NULL,
    secret character varying(128) COLLATE pg_catalog."default",
    CONSTRAINT config_oauth2_pkey PRIMARY KEY (appid)
)
WITH (
    OIDS = FALSE
);

CREATE TABLE public.users
(
    iid integer NOT NULL DEFAULT nextval('users_iid_seq'::regclass),
    userid character varying(64) COLLATE pg_catalog."default",
    cellid character varying(20) COLLATE pg_catalog."default",
    emailid character varying(128) COLLATE pg_catalog."default",
    pid integer DEFAULT nextval('users_pid_seq'::regclass),
    nick character varying(64) COLLATE pg_catalog."default",
    avatar character varying(256) COLLATE pg_catalog."default",
    passwd character varying(64) COLLATE pg_catalog."default",
    CONSTRAINT users_pkey PRIMARY KEY (iid)
)
WITH (
    OIDS = FALSE
);

CREATE TABLE public.users_oauth2
(
    openid character varying(128) COLLATE pg_catalog."default" NOT NULL,
    iid integer,
    CONSTRAINT users_oauth2_pkey PRIMARY KEY (openid)
)
WITH (
    OIDS = FALSE
);

CREATE TABLE public.roles
(
    orgid integer NOT NULL,
    roleid bigint NOT NULL,
    name character varying(128) COLLATE pg_catalog."default" NOT NULL,
    "desc" character varying(128) COLLATE pg_catalog."default",
    CONSTRAINT roles_pkey PRIMARY KEY (orgid, roleid)
)
WITH (
    OIDS = FALSE
);

CREATE TABLE public.roles_orgs
(
    orgid integer NOT NULL DEFAULT nextval('roles_orgid_seq'::regclass),
    orgname character varying COLLATE pg_catalog."default" NOT NULL,
    owneriid integer NOT NULL,
    CONSTRAINT roles_orgs_pkey PRIMARY KEY (orgid)
)
WITH (
    OIDS = FALSE
);
ALTER TABLE public.roles_orgs
    ADD CONSTRAINT roles_orgs_unique_orgname UNIQUE ;


CREATE TABLE public.roles_users
(
    orgid integer,
    roleid bigint,
    iid integer
)
WITH (
    OIDS = FALSE
);
