
CREATE TABLE stop_points
(
  id               serial PRIMARY KEY,
  StopPointNumber  varchar(40) NOT NULL,
  StopPointName    varchar(40) NOT NULL,
  StopAreaNumber   varchar(40) NOT NULL,
  StopAreaTypeCode varchar(40) NOT NULL,
  latitude         double precision NOT NULL,
  longitude        double precision NOT NULL
);

CREATE TABLE metro_stations
(
  id               serial PRIMARY KEY,
  SiteId           varchar(40) NOT NULL,
  SiteName         varchar(40) NOT NULL,
  latitude         double precision NOT NULL,
  longitude        double precision NOT NULL
);
