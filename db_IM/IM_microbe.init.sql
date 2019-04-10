/*
-- 1.1. Create IM_microbe_entity like genetic_entity:
--          ID (IM_microbe.entity_id) -> CELL
-- 1.2. Create IM_microbe like gene:
--          Entrez_gene_id -> IM_microbe.UNIQUE_MICROBE_ID - unique
--          Hugo_gene_symbol ->  IM_microbe.UNIQUE_MICROBE_NAME - unique
--          genetic_entity_id -> IM_microbe.MICROBE_ENTITY_ID - unique
-- 1.3. Create IM_microbe_alteration like genetic_alteration:
--          genetic_profile_id -> microbe_profile_id
--          genetic_entity_id -> microbeentity_id
-- 1.4. Create IM_microbe_profile like genetic_profile:
--          genetic_profile_id -> microbe_profile_id
--          genetic_alteration_type -> microbe_alteration_type
-- 1.5. Create IM_microbe_alias like gene_alias:
--          Entrez_gene_id -> IM_microbe.UNIQUE_MICROBE_ID
--					gene_alias -> MICROBE_ALIAS
*/

/* create necessary tables */

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
--  Table structure for `IM_microbe_entity`
-- ----------------------------
DROP TABLE IF EXISTS `IM_microbe_entity`;
CREATE TABLE `IM_microbe_entity` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `ENTITY_TYPE` varchar(45) NOT NULL DEFAULT '',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `IM_microbe`
-- ----------------------------
DROP TABLE IF EXISTS `IM_microbe`;
CREATE TABLE `IM_microbe` (
  `MICROBE_ENTITY_ID` int(11) NOT NULL,
  `UNIQUE_MICROBE_ID` int(11) NOT NULL,
  `UNIQUE_MICROBE_NAME` varchar(255) NOT NULL,
  `TYPE` varchar(50) DEFAULT NULL,
  `NABI_TAXON_ID` int(11) DEFAULT NULL,
  `NCBI_TAXON_NAME` varchar(255) DEFAULT NULL,
  `PARENT_ENTITY_ID` int(11) DEFAULT NULL,
  `PARENT_UNIQUE_NAME` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`MICROBE_ENTITY_ID`),
  UNIQUE KEY `UNIQUE_MICROBE_ID` (`UNIQUE_MICROBE_ID`),
  KEY `UNIQUE_MICROBE_NAME` (`UNIQUE_MICROBE_NAME`),
  CONSTRAINT `im_microbe_x_entity` FOREIGN KEY (`MICROBE_ENTITY_ID`) REFERENCES `IM_microbe_entity` (`ID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `IM_microbe_profile`
-- ----------------------------
DROP TABLE IF EXISTS `IM_microbe_profile`;
CREATE TABLE `IM_microbe_profile` (
  `MICROBE_PROFILE_ID` int(11) NOT NULL AUTO_INCREMENT,
  `STABLE_ID` varchar(255) NOT NULL,
  `CANCER_STUDY_ID` int(11) NOT NULL,
  `MICROBE_ALTERATION_TYPE` varchar(255) NOT NULL,
  `DATATYPE` varchar(255) NOT NULL,
  `NAME` varchar(255) NOT NULL,
  `DESCRIPTION` mediumtext,
  `SHOW_PROFILE_IN_ANALYSIS_TAB` tinyint(1) NOT NULL,
  PRIMARY KEY (`MICROBE_PROFILE_ID`),
  UNIQUE KEY `STABLE_ID` (`STABLE_ID`),
  KEY `CANCER_STUDY_ID` (`CANCER_STUDY_ID`),
  CONSTRAINT `im_microbe_x_profile` FOREIGN KEY (`CANCER_STUDY_ID`) REFERENCES `cancer_study` (`CANCER_STUDY_ID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `IM_microbe_alteration`
-- ----------------------------
DROP TABLE IF EXISTS `IM_microbe_alteration`;
CREATE TABLE `IM_microbe_alteration` (
  `MICROBE_PROFILE_ID` int(11) NOT NULL,
  `MICROBE_ENTITY_ID` int(11) NOT NULL,
  `VALUES` longtext NOT NULL,
  PRIMARY KEY (`MICROBE_PROFILE_ID`,`MICROBE_ENTITY_ID`),
  KEY `MICROBE_ENTITY_ID` (`MICROBE_ENTITY_ID`),
  CONSTRAINT `im_microbe_alteration_x_profile` FOREIGN KEY (`MICROBE_PROFILE_ID`) REFERENCES `IM_microbe_profile` (`MICROBE_PROFILE_ID`) ON DELETE CASCADE,
  CONSTRAINT `im_microbe_alteration_x_entity` FOREIGN KEY (`MICROBE_ENTITY_ID`) REFERENCES `IM_microbe_entity` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `IM_microbe_alias`
-- ----------------------------
DROP TABLE IF EXISTS `IM_microbe_alias`;
CREATE TABLE `IM_microbe_alias` (
  `UNIQUE_MICROBE_ID` int(11) NOT NULL, 
  `MICROBE_ALIAS` varchar(255) NOT NULL,
  PRIMARY KEY (`UNIQUE_MICROBE_ID`,`MICROBE_ALIAS`),
  CONSTRAINT `im_microbe_alias_x_cell` FOREIGN KEY (`UNIQUE_MICROBE_ID`) REFERENCES `IM_microbe` (`UNIQUE_MICROBE_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `IM_microbe_profile_samples`
-- ----------------------------
DROP TABLE IF EXISTS `IM_microbe_profile_samples`;
CREATE TABLE `IM_microbe_profile_samples` (
  `MICROBE_PROFILE_ID` int(11) NOT NULL,
  `ORDERED_SAMPLE_LIST` longtext NOT NULL,
  UNIQUE KEY `MICROBE_PROFILE_ID` (`MICROBE_PROFILE_ID`),
  CONSTRAINT `im_microbe_profile_samples_x_microbe_profile` FOREIGN KEY (`MICROBE_PROFILE_ID`) REFERENCES `IM_microbe_profile` (`MICROBE_PROFILE_ID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `IM_microbe_profile_link`
-- ----------------------------
DROP TABLE IF EXISTS `IM_microbe_profile_link`;
CREATE TABLE `IM_microbe_profile_link` (
  `REFERRING_MICROBE_PROFILE_ID` int(11) NOT NULL,
  `REFERRED_MICROBE_PROFILE_ID` int(11) NOT NULL,
  `REFERENCE_TYPE` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`REFERRING_MICROBE_PROFILE_ID`,`REFERRED_MICROBE_PROFILE_ID`),
  KEY `REFERRED_MICROBE_PROFILE_ID` (`REFERRED_MICROBE_PROFILE_ID`),
  CONSTRAINT `im_microbe_profile_link_x_microbe_profile_1` FOREIGN KEY (`REFERRING_MICROBE_PROFILE_ID`) REFERENCES `IM_microbe_profile` (`MICROBE_PROFILE_ID`) ON DELETE CASCADE,
  CONSTRAINT `im_microbe_profile_link_x_microbe_profile_2` FOREIGN KEY (`REFERRED_MICROBE_PROFILE_ID`) REFERENCES `IM_microbe_profile` (`MICROBE_PROFILE_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `IM_sample_microbe_profile`
-- ----------------------------

CREATE TABLE `IM_sample_microbe_profile` (
  `SAMPLE_ID` int(11) NOT NULL,
  `MICROBE_PROFILE_ID` int(11) NOT NULL,
  `PANEL_ID` int(11) DEFAULT NULL,
  UNIQUE KEY `UQ_SAMPLE_ID_MICROBE_PROFILE_ID` (`SAMPLE_ID`,`MICROBE_PROFILE_ID`), -- Constraint to allow each sample only once in each profile
  KEY (`SAMPLE_ID`),
  FOREIGN KEY (`MICROBE_PROFILE_ID`) REFERENCES `IM_microbe_profile` (`MICROBE_PROFILE_ID`) ON DELETE CASCADE,
  FOREIGN KEY (`SAMPLE_ID`) REFERENCES `sample` (`INTERNAL_ID`) ON DELETE CASCADE
);
-- FOREIGN KEY (`PANEL_ID`) REFERENCES `IM_gene_panel` (`INTERNAL_ID`) ON DELETE RESTRICT

/* populate microbe entries from BS */

-- A paradigm to generate auto key column
/*
SELECT @row := @row + 1 as MICROBE_ENTITY_ID, t.*
FROM CP_cell t, (SELECT @row := 0) AS r 
*/

/*
-- populate IM_microbe using CP_cell
INSERT INTO `IM_microbe` (`MICROBE_ENTITY_ID`, `UNIQUE_MICROBE_ID`, `UNIQUE_MICROBE_NAME`, `TYPE`, `PARENT_ENTITY_NAME`, `NABI_TAXON_ID`, `NCBI_TAXON_NAME`, `PARENT_ENTITY_ID`)
SELECT `MICROBE_ENTITY_ID`,`UNIQUE_MICROBE_ID`, `UNIQUE_MICROBE_NAME`, `TYPE`, `PARENT_ENTITY_NAME`, `NABI_TAXON_ID`, `NCBI_TAXON_NAME`, `PARENT_ENTITY_ID`
FROM ( 
	SELECT @row := @row + 1 as `MICROBE_ENTITY_ID`, t.*
	FROM `CP_cell` t, (
		SELECT @row := 0
	) tmp_table
) CP_microbeindexed;

-- populate IM_microbe_entity
INSERT INTO IM_microbe_entity (`ENTITY_TYPE`, `ID`)
SELECT 'CELL', `MICROBE_ENTITY_ID` FROM `IM_microbe`;
*/

/* add entries that are not curated in CellPedia database */
/*
# Known missing types and type mapping:
#
# T.cells.CD8 -> CD8+ cytotoxic T lymphocyte (20)
# T.cells.CD4.memory.resting ->  Central CD4+ memory T (Tem) cell (33)
# T.cells.CD4.memory.activated -> Effector CD4+ memory T (Tem) cell (19)
# NK.cells -> Natural killer cell (46)
# NK.cells.resting -> Resting Natural killer cell (46 + 1,000,000,000)
# NK.cells.activated -> Activated Natural killer cell (46 + 1,000,000,001)
# Macrophages.M0 -> Macrophage (9)
# Dendritic.cells -> Myeloid Dendritic cell 43, 44
# Dendritic.cells.resting -> Resting dendritic cell (43 + 1,000,000,000), cell type mapped to mDC (32)
# Dendritic.cells.activated -> Activated dendritic cell (44 + 1,000,000,000), cell type mapped to amDC (9)
# Mast.cells -> Mast cell (54)
# Mast.cells.resting -> Resting Mast cell (54 + 1,000,000,000)
# Mast.cells.activated -> Activated Master cell (54 + 1,000,000,001)
*/

-- A paradigm to get the next auto_increment key
/*
SELECT AUTO_INCREMENT
FROM information_schema.tables
WHERE table_name = 'IM_microbe_entity'
AND table_schema = DATABASE();
*/

-- Generate Keys and Insert Values to IM_microbe and IM_microbe_entity
/*
DROP TABLE IF EXISTS `IM_microbe_tmp`;
CREATE TABLE `IM_microbe_tmp` LIKE IM_microbe;
INSERT INTO `IM_microbe_tmp` (`MICROBE_ENTITY_ID`, `UNIQUE_MICROBE_ID`, `UNIQUE_MICROBE_NAME`, `TYPE`, `PARENT_ENTITY_NAME`, `NABI_TAXON_ID`, `NCBI_TAXON_NAME`, `PARENT_ENTITY_ID`)
VALUES
  (1, 1000000046, 'Resting Natural killer cell',             'Natural killer cell', 'Blood', NULL, NULL, 261),
  (2, 1000000047, 'Activated Natural killer cell',           'Natural killer cell', 'Blood', NULL, NULL, 261),
  (3, 1000000043, 'Resting Dendritic cell',                  'Dendritic cell',      'Blood', NULL, NULL, 32),
  (4, 1000000044, 'Activated Dendritic cell',                'Dendritic cell',      'Blood', NULL, NULL, 32),
  (5, 1000000054, 'Resting Mast cell',                       'Mast cell',           'Blood', NULL, NULL, 10),
  (6, 1000000055, 'Activated Mast cell',                     'Mast cell',           'Blood', NULL, NULL, 10);
SET @auto_shift_tmp := ( SELECT AUTO_INCREMENT
	FROM information_schema.tables
	WHERE table_name = 'IM_microbe_entity'
	AND table_schema = DATABASE() );
UPDATE `IM_microbe_tmp` SET `MICROBE_ENTITY_ID` = `MICROBE_ENTITY_ID` + @auto_shift_tmp;
INSERT INTO `IM_microbe`
SELECT * FROM `IM_microbe_tmp`;
INSERT INTO `IM_microbe_entity` (`ENTITY_TYPE`, `ID`)
SELECT 'CELL', `MICROBE_ENTITY_ID` FROM `IM_microbe_tmp`;
-- SELECT * FROM IM_microbe_tmp;
-- SELECT `UNIQUE_MICROBE_NAME`, `MICROBE_ENTITY_ID` FROM IM_microbe order by microbeentity_id desc limit 10;
-- SELECT * FROM IM_microbe_entity order by id desc limit 10;

-- clean up
DROP TABLE `IM_microbe_tmp`;
SET FOREIGN_KEY_CHECKS = 0;
*/

-- echo "docker exec -it cbioDB1 sh -c \"mysql -ucbio1 -pP@ssword1 cbioportal1\" "
