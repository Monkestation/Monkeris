Any time you make a change to the schema files, remember to increment the database schema version. Generally increment the minor number, major should be reserved for significant changes to the schema. Both values go up to 255.

Make sure to also update `DB_MAJOR_VERSION` and `DB_MINOR_VERSION`, which can be found in `code/__DEFINES/subsystem.dm`.

The latest database version is 3.0; The query to update the schema revision table is:

```sql
INSERT INTO `schema_revision` (`major`, `minor`) VALUES (3, 1);
```


In any query remember to add a prefix to the table names if you use one.

-----------------------------------------------------
Version 3.1 3 October 2025, by Flleeppyy
Alter `library` table to add , add `library_action` table.

```sql
ALTER TABLE `library`
DROP FOREIGN KEY `fk_rails_53d51ce16a`,
DROP INDEX `index_library_on_author_id`,
CHANGE COLUMN `author` `author` VARCHAR(45) NOT NULL ,
CHANGE COLUMN `title` `title` VARCHAR(45) NOT NULL ,
CHANGE COLUMN `content` `content` TEXT NOT NULL ,
CHANGE COLUMN `category` `category` ENUM('Any','Fiction','Non-Fiction','Adult','Reference','Religion') NOT NULL ,
CHANGE COLUMN `author_id` `ckey` VARCHAR(32) NOT NULL DEFAULT 'LEGACY' ,
CHANGE COLUMN `created_at` `datetime` DATETIME NOT NULL ,
DROP COLUMN `updated_at`,
ADD COLUMN `round_id_created` INT(11) UNSIGNED NULL AFTER `deleted`,
ADD INDEX `deleted_idx` (`deleted` ASC),
ADD INDEX `idx_lib_id_del` (`id` ASC, `deleted` ASC),
ADD INDEX `idx_lib_del_title` (`deleted` ASC, `title` ASC),
ADD INDEX `idx_lib_search` (`deleted` ASC, `author` ASC, `title` ASC, `category` ASC);

CREATE TABLE `library_action` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `book` int(10) unsigned NOT NULL,
  `reason` longtext DEFAULT NULL,
  `ckey` varchar(32) NOT NULL DEFAULT '',
  `datetime` datetime NOT NULL DEFAULT current_timestamp(),
  `action` varchar(11) NOT NULL DEFAULT '',
  `ip_addr` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8mb4;
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
