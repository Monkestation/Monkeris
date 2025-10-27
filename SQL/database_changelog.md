Any time you make a change to the schema files, remember to increment the database schema version. Generally increment the minor number, major should be reserved for significant changes to the schema. Both values go up to 255.

Make sure to also update `DB_MAJOR_VERSION` and `DB_MINOR_VERSION`, which can be found in `code/__DEFINES/subsystem.dm`.

The latest database version is 3.2; The query to update the schema revision table is:

```sql
INSERT INTO `schema_revision` (`major`, `minor`) VALUES (3, 2);
```


In any query remember to add a prefix to the table names if you use one.
-----------------------------------------------------
Version 3.2 27 October 2025, by Flleeppyy
Add `feedback`, `legacy_population`, `role_time` and `role_time_log` tables

```sql

CREATE TABLE `feedback` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `datetime` datetime NOT NULL,
  `round_id` int(11) unsigned NULL,
  `key_name` varchar(32) NOT NULL,
  `key_type` enum('text', 'amount', 'tally', 'nested tally', 'associative') NOT NULL,
  `version` tinyint(3) unsigned NOT NULL,
  `json` json NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `legacy_population` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `playercount` int(11) DEFAULT NULL,
  `admincount` int(11) DEFAULT NULL,
  `time` datetime NOT NULL,
  `server_ip` int(10) unsigned NOT NULL,
  `server_port` smallint(5) unsigned NOT NULL,
  `round_id` int(11) unsigned NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `role_time`
( `ckey` VARCHAR(32) NOT NULL ,
 `job` VARCHAR(32) NOT NULL ,
 `minutes` INT UNSIGNED NOT NULL,
 PRIMARY KEY (`ckey`, `job`)
 ) ENGINE = InnoDB;


CREATE TABLE `role_time_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `ckey` varchar(32) NOT NULL,
  `job` varchar(128) NOT NULL,
  `delta` int(11) NOT NULL,
  `datetime` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `ckey` (`ckey`),
  KEY `job` (`job`),
  KEY `datetime` (`datetime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DELIMITER $$
CREATE PROCEDURE `set_poll_deleted`(
	IN `poll_id` INT
)
SQL SECURITY INVOKER
BEGIN
UPDATE `poll_question` SET deleted = 1 WHERE id = poll_id;
UPDATE `poll_option` SET deleted = 1 WHERE pollid = poll_id;
UPDATE `poll_vote` SET deleted = 1 WHERE pollid = poll_id;
UPDATE `poll_textreply` SET deleted = 1 WHERE pollid = poll_id;
END
$$
CREATE TRIGGER `role_timeTlogupdate` AFTER UPDATE ON `role_time` FOR EACH ROW BEGIN INSERT into role_time_log (ckey, job, delta) VALUES (NEW.CKEY, NEW.job, NEW.minutes-OLD.minutes);
END
$$
CREATE TRIGGER `role_timeTloginsert` AFTER INSERT ON `role_time` FOR EACH ROW BEGIN INSERT into role_time_log (ckey, job, delta) VALUES (NEW.ckey, NEW.job, NEW.minutes);
END
$$
CREATE TRIGGER `role_timeTlogdelete` AFTER DELETE ON `role_time` FOR EACH ROW BEGIN INSERT into role_time_log (ckey, job, delta) VALUES (OLD.ckey, OLD.job, 0-OLD.minutes);
END
$$
DELIMITER ;
```

-----------------------------------------------------
Version 3.1 7 October 2025, by Flleeppyy
Remove `stickyban` and its related tables.

```sql
DROP TABLE IF EXISTS `stickyban`;
DROP TABLE IF EXISTS `stickyban_matched_ckey`;
DROP TABLE IF EXISTS `stickyban_matched_ip`;
DROP TABLE IF EXISTS `stickyban_matched_cid`;
```
-----------------------------------------------------
Version 3.0 3 October 2025, by Flleeppyy
Add `admin_log`, `admin_ranks` table

```sql
CREATE TABLE `admin_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `datetime` datetime NOT NULL,
  `round_id` int(11) unsigned NULL,
  `adminckey` varchar(32) NOT NULL,
  `adminip` int(10) unsigned NOT NULL,
  `operation` enum('add admin','remove admin','change admin rank','add rank','remove rank','change rank flags') NOT NULL,
  `target` varchar(32) NOT NULL,
  `log` varchar(1000) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `admin_ranks` (
  `rank` varchar(32) NOT NULL,
  `flags` smallint(5) unsigned NOT NULL,
  `exclude_flags` smallint(5) unsigned NOT NULL,
  `can_edit_flags` smallint(5) unsigned NOT NULL,
  PRIMARY KEY (`rank`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
```
-----------------------------------------------------
Version 2.0 5 September 2025, by Flleeppyy
Add `messages` table

```sql
CREATE TABLE `messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` enum('memo','message','message sent','note','watchlist entry') NOT NULL,
  `targetckey` varchar(32) NOT NULL,
  `adminckey` varchar(32) NOT NULL,
  `text` varchar(2048) NOT NULL,
  `timestamp` datetime NOT NULL,
  `server` varchar(32) DEFAULT NULL,
  `server_ip` int(10) unsigned NOT NULL,
  `server_port` smallint(5) unsigned NOT NULL,
  `round_id` int(11) unsigned NULL,
  `secret` tinyint(1) unsigned NOT NULL,
  `expire_timestamp` datetime DEFAULT NULL,
  `severity` enum('high','medium','minor','none') DEFAULT NULL,
  `playtime` int(11) unsigned NULL DEFAULT NULL,
  `lasteditor` varchar(32) DEFAULT NULL,
  `edits` text,
  `deleted` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `deleted_ckey` VARCHAR(32) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_msg_ckey_time` (`targetckey`,`timestamp`, `deleted`),
  KEY `idx_msg_type_ckeys_time` (`type`,`targetckey`,`adminckey`,`timestamp`, `deleted`),
  KEY `idx_msg_type_ckey_time_odr` (`type`,`targetckey`,`timestamp`, `deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
```
-----------------------------------------------------
Version 1.0 16 March 2025, by Flleeppyy
Add `byond_build` and `byond_version` to the `connection_log` table.

```sql
ALTER TABLE `connection_log` ADD COLUMN `byond_version` varchar(8) DEFAULT NULL, ADD COLUMN `byond_build` varchar(255) DEFAULT NULL;
```
-----------------------------------------------------
