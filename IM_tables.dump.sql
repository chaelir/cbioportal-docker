/*
-- 1.1. Create IM_microbe_entity like genetic_entity:
--          ID(BS.taxon.taxon_id) -> MICROBE
-- 1.2. Create IM_microbe_profile like genetic_profile:
--          genetic_profile_id -> microbe_profile_id,
--          genetic_alteration_type -> microbe_alteration_type,
--          stable_id,
--          cancer_study_id,
--          data_type,
--          name,
--          description
-- 1.3. Create IM_microbe_alteration like genetic_alteration:
--          genetic_profile_id -> microbe_profile_id
--          genetic_entity_id -> microbe_entity_id
-- 1.4. Create IM_microbe like gene
--          Entrez_gene_id -> ncbi_taxon_id (i.e. BS.taxon.ncbi_taxon_id) - unique
--          Hugo_gene_symbol -> ncbi_taxon_name (i.e. BS.taxon.ncbi_taxon_name) - unique
--          genetic_entity_id -> microbe_entity_id (i.e. BS.taxon.taxon_id) - unique
--          type -> type (i.e. BS.taxon.node_rank) ?
--          length,
-- 2.1. Create IM_cell_entity like genetic_entity:
--          ID (CP.differentiated.cell_id) -> CELL
-- 2.2. Create IM_cell like gene
--          Entrez_gene_id -> cellpedia_cell_type_id (i.e. CP.celltype.cell_type_id) - non-unique
--          Hugo_gene_symbol -> cellpedia_cell_type_name (i.e. CP.celltype.cell_type_name) - non-unique
--          genetic_entity_id -> cell_entity_id (i.e. CP.differentiated.cell_id) - unique
--          cytoband -> organ (i.e. CP_anatomy.organ) ?
--          type : differentiated / progenitor
--          length,
-- 2.3. Create IM_cell_alteration like genetic_alteration:
--          genetic_profile_id -> cell_profile_id
--          genetic_entity_id -> cell_entity_id
-- 2.4. Create IM_cell_profile like genetic_profile:
--          genetic_profile_id -> cell_profile_id,
--          genetic_alteration_type -> cell_alteration_type,
--          stable_id,
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `IM_cell`;
DROP TABLE IF EXISTS `IM_cell_entity`;
DROP TABLE IF EXISTS `IM_cell_profile`;
DROP TABLE IF EXISTS `IM_cell_alteration`;
DROP TABLE IF EXISTS `IM_microbe`;
DROP TABLE IF EXISTS `IM_microbe_entity`;
DROP TABLE IF EXISTS `IM_microbe_profile`;
DROP TABLE IF EXISTS `IM_microbe_alteration`;

-- ----------------------------
--  Table structure for `IM_cell_entity`
-- ----------------------------
DROP TABLE IF EXISTS `IM_cell_entity`;
CREATE TABLE `IM_cell_entity` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `ENTITY_TYPE` varchar(45) NOT NULL DEFAULT '',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS = 1;

-- ----------------------------
--  Table structure for `IM_cell`
-- ----------------------------
DROP TABLE IF EXISTS `IM_cell`;
CREATE TABLE `IM_cell` (
  `CELLPEDIA_CELL_TYPE_ID` int(11) NOT NULL DEFAULT -1,
  `CELLPEDIA_CELL_TYPE_NAME` varchar(255) NOT NULL DEFAULT '',
  `CELL_ENTITY_ID` int(11) NOT NULL DEFAULT -1,
  `TYPE` varchar(50) DEFAULT NULL,
  `ORGAN` varchar(64) DEFAULT NULL,
  `LENGTH` int(11) DEFAULT NULL,
  PRIMARY KEY (`CELL_ENTITY_ID`),
  UNIQUE KEY `CELL_ENTITY_ID_UNIQUE` (`CELL_ENTITY_ID`),
  KEY `CELLPEDIA_CELL_TYPE_NAME` (`CELLPEDIA_CELL_TYPE_NAME`),
  CONSTRAINT `im_cell_ibfk_1` FOREIGN KEY (`CELL_ENTITY_ID`) REFERENCES `IM_cell_entity` (`ID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS = 1;

-- ----------------------------
--  Table structure for `IM_cell_profile`
-- ----------------------------
DROP TABLE IF EXISTS `IM_cell_profile`;
CREATE TABLE `IM_cell_profile` (
  `CELL_PROFILE_ID` int(11) NOT NULL AUTO_INCREMENT,
  `STABLE_ID` varchar(255) NOT NULL,
  `CANCER_STUDY_ID` int(11) NOT NULL,
  `CELL_ALTERATION_TYPE` varchar(255) NOT NULL,
  `DATATYPE` varchar(255) NOT NULL,
  `NAME` varchar(255) NOT NULL,
  `DESCRIPTION` mediumtext,
  `SHOW_PROFILE_IN_ANALYSIS_TAB` tinyint(1) NOT NULL,
  PRIMARY KEY (`CELL_PROFILE_ID`),
  UNIQUE KEY `STABLE_ID` (`STABLE_ID`),
  KEY `CANCER_STUDY_ID` (`CANCER_STUDY_ID`),
  CONSTRAINT `im_cell_profile_ibfk_1` FOREIGN KEY (`CANCER_STUDY_ID`) REFERENCES `cancer_study` (`CANCER_STUDY_ID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS = 1;

-- ----------------------------
--  Table structure for `IM_cell_alteration`
-- ----------------------------
DROP TABLE IF EXISTS `IM_cell_alteration`;
CREATE TABLE `IM_cell_alteration` (
  `CELL_PROFILE_ID` int(11) NOT NULL,
  `CELL_ENTITY_ID` int(11) NOT NULL,
  `VALUES` longtext NOT NULL,
  PRIMARY KEY (`CELL_PROFILE_ID`,`CELL_ENTITY_ID`),
  KEY `CELL_ENTITY_ID` (`CELL_ENTITY_ID`),
  CONSTRAINT `im_cell_alteration_copy_ibfk_1` FOREIGN KEY (`CELL_PROFILE_ID`) REFERENCES `IM_cell_profile` (`CELL_PROFILE_ID`) ON DELETE CASCADE,
  CONSTRAINT `im_cell_alteration_copy_ibfk_2` FOREIGN KEY (`CELL_ENTITY_ID`) REFERENCES `IM_cell_entity` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS = 1;

-- ----------------------------
--  Table structure for `IM_microbe_entity`
-- ----------------------------
DROP TABLE IF EXISTS `IM_microbe_entity`;
CREATE TABLE `IM_microbe_entity` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `ENTITY_TYPE` varchar(45) NOT NULL DEFAULT '',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS = 1;

-- ----------------------------
--  Table structure for `IM_microbe`
-- ----------------------------
DROP TABLE IF EXISTS `IM_microbe`;
CREATE TABLE `IM_microbe` (
  `NCBI_TAXON_ID` int(11) NOT NULL DEFAULT -1,
  `NCBI_TAXON_NAME` varchar(255) NOT NULL DEFAULT '',
  `MICROBE_ENTITY_ID` int(11) NOT NULL,
  `TYPE` varchar(50) DEFAULT NULL DEFAULT '',
  `TAXON_LEVEL` varchar(64) DEFAULT NULL DEFAULT '',
  `LENGTH` int(11) DEFAULT NULL DEFAULT -1,
  PRIMARY KEY (`MICROBE_ENTITY_ID`),
  UNIQUE KEY `MICROBE_ENTITY_ID_UNIQUE` (`MICROBE_ENTITY_ID`),
  KEY `NCBI_TAXON_NAME` (`NCBI_TAXON_NAME`),
  CONSTRAINT `im_microbe_ibfk_1` FOREIGN KEY (`MICROBE_ENTITY_ID`) REFERENCES `IM_microbe_entity` (`ID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS = 1;

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
  CONSTRAINT `im_microbe_profile_ibfk_1` FOREIGN KEY (`CANCER_STUDY_ID`) REFERENCES `cancer_study` (`CANCER_STUDY_ID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS = 1;

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
  CONSTRAINT `im_microbe_alteration_ibfk_1` FOREIGN KEY (`MICROBE_PROFILE_ID`) REFERENCES `IM_microbe_profile` (`MICROBE_PROFILE_ID`) ON DELETE CASCADE,
  CONSTRAINT `im_microbe_alteration_ibfk_2` FOREIGN KEY (`MICROBE_ENTITY_ID`) REFERENCES `IM_microbe_entity` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS = 1;

/* populate cell entries from CP */

-- cell_entity
insert into IM_cell_entity (ID)
select CONVERT(Cell_ID, SIGNED) from CP_differentiated;
UPDATE IM_cell_entity SET ENTITY_TYPE='CELL';

insert into IM_cell (Cell_Entity_ID)
select CONVERT(Cell_ID, SIGNED) from CP_differentiated;

-- cell
UPDATE IM_cell
INNER JOIN CP_differentiated ON (IM_cell.Cell_Entity_ID = CONVERT(CP_differentiated.Cell_ID, SIGNED))
SET IM_cell.CELLPEDIA_CELL_TYPE_ID = CP_differentiated.Cell_Type_ID;

UPDATE IM_cell
INNER JOIN CP_differentiated ON (IM_cell.Cell_Entity_ID = CONVERT(CP_differentiated.Cell_ID, SIGNED))
SET IM_cell.CELLPEDIA_CELL_TYPE_NAME = CP_differentiated.Cell_Type_Name;

UPDATE IM_cell
INNER JOIN CP_differentiated ON (IM_cell.Cell_Entity_ID = CONVERT(CP_differentiated.Cell_ID, SIGNED))
SET IM_cell.Organ = CP_differentiated.Organ;

UPDATE IM_cell SET TYPE='DIFFERENTIATED';

/* populate microbe entries from BS */

-- microbe_entity
insert into IM_microbe_entity (ID)
select taxon_id from BS_taxon;
UPDATE IM_microbe_entity SET ENTITY_TYPE='MICROBE';

insert into IM_microbe (Microbe_Entity_ID)
select taxon_id from BS_taxon;

-- microbe
UPDATE IM_microbe
INNER JOIN BS_taxon ON (IM_microbe.MICROBE_ENTITY_ID = BS_taxon.taxon_id)
SET IM_microbe.NCBI_TAXON_ID = BS_taxon.ncbi_taxon_id;

UPDATE IM_microbe
INNER JOIN BS_taxon ON (IM_microbe.MICROBE_ENTITY_ID = BS_taxon.taxon_id)
SET IM_microbe.TYPE = BS_taxon.node_rank;

UPDATE IM_microbe
INNER JOIN BS_taxon_name ON (IM_microbe.MICROBE_ENTITY_ID = BS_taxon_name.taxon_id)
SET IM_microbe.NCBI_TAXON_NAME = BS_taxon_name.`name`;
