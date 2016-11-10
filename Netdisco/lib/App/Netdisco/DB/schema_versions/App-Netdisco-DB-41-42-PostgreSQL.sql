BEGIN;

CREATE TABLE node_ip_l3device
(
  node_mac macaddr NOT NULL,
  node_ip inet NOT NULL,
  device_ip inet NOT NULL,
  time_first timestamp without time zone DEFAULT now(),
  time_last timestamp without time zone DEFAULT now(),
  CONSTRAINT node_ip_l3device_pkey PRIMARY KEY (node_mac, node_ip, device_ip)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE node_ip_l3device
  OWNER TO netdisco;

COMMIT;
