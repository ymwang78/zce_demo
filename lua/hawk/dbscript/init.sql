CREATE SEQUENCE public.roles_orgid_seq;
CREATE SEQUENCE public.users_iid_seq;
CREATE SEQUENCE public.users_pid_seq;

CREATE TABLE public.config_ad
(
    appid character varying(32) NOT NULL,
	areaid character varying(4) NOT NULL,
    adid character varying(128) NOT NULL,
    width integer,
    height integer,
    properties character varying(4096) ,
    CONSTRAINT config_ad_pkey PRIMARY KEY (appid, areaid, adid)
)
WITH (
    OIDS = FALSE
);

CREATE TABLE public.config_app
(
    appid character varying(4)  NOT NULL,
    areaid character varying(4)  NOT NULL,
    gameid character varying(4)  NOT NULL,
    key character varying(128)  NOT NULL,
    value character varying(8192)  NOT NULL,
    CONSTRAINT config_app_pkey PRIMARY KEY (appid, areaid, gameid, key)
)
WITH (
    OIDS = FALSE
);

CREATE TABLE public.config_message
(
    appid character varying(32) NOT NULL,
    areaid character varying(4) NOT NULL,
    catalog character varying(32) NOT NULL,
    title character varying(254) NOT NULL,
    content character varying(4096) ,
    sortseq integer
)
WITH (
    OIDS = FALSE
);

CREATE TABLE public.config_oauth2
(
    appid character varying(128)  NOT NULL,
    secret character varying(128) ,
    CONSTRAINT config_oauth2_pkey PRIMARY KEY (appid)
)
WITH (
    OIDS = FALSE
);

CREATE TABLE public.users
(
    iid integer NOT NULL DEFAULT nextval('users_iid_seq'::regclass),
    userid character varying(64) ,
    cellid character varying(20) ,
    emailid character varying(128) ,
    pid integer DEFAULT nextval('users_pid_seq'::regclass),
    nick character varying(64) ,
    avatar character varying(256) ,
    passwd character varying(64) ,
    issuperadmin boolean,
    idname character varying(64) ,
    idcard character varying(64) ,
    idcardtype character varying(64) ,
    cellidverified boolean,
    emailidverified boolean,
    idcardverified boolean,
    CONSTRAINT users_pkey PRIMARY KEY (iid),
    CONSTRAINT users_unique_cellid UNIQUE (cellid),
    CONSTRAINT users_unique_emailid UNIQUE (emailid),
    CONSTRAINT users_unique_idcard UNIQUE (idcard)
)
WITH (
    OIDS = FALSE
);

CREATE TABLE public.users_oauth2
(
    openid character varying(128)  NOT NULL,
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
    name character varying(128)  NOT NULL,
    "desc" character varying(128) ,
    CONSTRAINT roles_pkey PRIMARY KEY (orgid, roleid)
)
WITH (
    OIDS = FALSE
);

CREATE TABLE public.roles_orgs
(
    orgid integer NOT NULL DEFAULT nextval('roles_orgid_seq'::regclass),
    orgname character varying  NOT NULL,
    owneriid integer NOT NULL,
    CONSTRAINT roles_orgs_pkey PRIMARY KEY (orgid)
)
WITH (
    OIDS = FALSE
);
ALTER TABLE public.roles_orgs
    ADD CONSTRAINT roles_orgs_unique_orgname UNIQUE (orgname);


CREATE TABLE public.roles_users
(
    orgid integer,
    roleid bigint,
    iid integer
)
WITH (
    OIDS = FALSE
);

CREATE TABLE public.users_package
(
    iid integer NOT NULL,
    "package" jsonb,
    CONSTRAINT users_package_pkey PRIMARY KEY (iid)
)
WITH (
    OIDS = FALSE
);
