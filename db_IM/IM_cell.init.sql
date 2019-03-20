/*
-- 2.1. Create IM_cell_entity like genetic_entity:
--          ID (IM_cell.entity_id) -> CELL
-- 2.2. Create IM_cell like gene:
--          Entrez_gene_id -> IM_cell.UNIQUE_CELL_ID - unique
--          Hugo_gene_symbol ->  IM_cell.UNIQUE_CELL_NAME - unique
--          genetic_entity_id -> IM_cell.CELL_ENTITY_ID - unique
-- 2.3. Create IM_cell_alteration like genetic_alteration:
--          genetic_profile_id -> cell_profile_id
--          genetic_entity_id -> cell_entity_id
-- 2.4. Create IM_cell_profile like genetic_profile:
--          genetic_profile_id -> cell_profile_id
--          genetic_alteration_type -> cell_alteration_type
-- 2.5. Create IM_cell_alias like gene_alias:
--          Entrez_gene_id -> IM_cell.UNIQUE_CELL_ID
--					gene_alias -> CELL_ALIAS
*/

/* create necessary tables */

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `IM_cell_entity`;
DROP TABLE IF EXISTS `IM_cell`;
DROP TABLE IF EXISTS `IM_cell_profile`;
DROP TABLE IF EXISTS `IM_cell_alteration`;
DROP TABLE IF EXISTS `IM_cell_alias`;

-- ----------------------------
--  Table structure for `IM_cell_entity`
-- ----------------------------
DROP TABLE IF EXISTS `IM_cell_entity`;
CREATE TABLE `IM_cell_entity` (
  `ID` int(11) NOT NULL,
  `ENTITY_TYPE` varchar(45) NOT NULL DEFAULT '',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `IM_cell`
-- ----------------------------
DROP TABLE IF EXISTS `IM_cell`;
CREATE TABLE `IM_cell` (
  `CELL_ENTITY_ID` int(11) NOT NULL AUTO_INCREMENT,
  `UNIQUE_CELL_ID` int(11) NOT NULL,
  `UNIQUE_CELL_NAME` varchar(255) NOT NULL,
  `TYPE` varchar(50) DEFAULT NULL,
  `ORGAN` varchar(64) DEFAULT NULL,
  `CPID` int(11) DEFAULT NULL,
  `ANATOMY_ID` varchar(255) DEFAULT NULL,
  `CELL_TYPE_ID` int(11) DEFAULT NULL,
  PRIMARY KEY (`CELL_ENTITY_ID`),
  UNIQUE KEY `UNIQUE_CELL_ID` (`UNIQUE_CELL_ID`),
  KEY `UNIQUE_CELL_NAME` (`UNIQUE_CELL_NAME`),
  CONSTRAINT `im_cell_x_entity` FOREIGN KEY (`CELL_ENTITY_ID`) REFERENCES `IM_cell_entity` (`ID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
  CONSTRAINT `im_cell_x_profile` FOREIGN KEY (`CANCER_STUDY_ID`) REFERENCES `cancer_study` (`CANCER_STUDY_ID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
  CONSTRAINT `im_cell_alteration_x_profile` FOREIGN KEY (`CELL_PROFILE_ID`) REFERENCES `IM_cell_profile` (`CELL_PROFILE_ID`) ON DELETE CASCADE,
  CONSTRAINT `im_cell_alteration_x_entity` FOREIGN KEY (`CELL_ENTITY_ID`) REFERENCES `IM_cell_entity` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `IM_cell_alias`
-- ----------------------------
DROP TABLE IF EXISTS `IM_cell_alias`;
CREATE TABLE `IM_cell_alias` (
  `UNIQUE_CELL_ID` int(11) NOT NULL, 
  `CELL_ALIAS` varchar(255) NOT NULL,
  PRIMARY KEY (`UNIQUE_CELL_ID`,`CELL_ALIAS`),
  CONSTRAINT `im_cell_alias_x_cell` FOREIGN KEY (`UNIQUE_CELL_ID`) REFERENCES `IM_cell` (`UNIQUE_CELL_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/* populate cell entries from CP */

-- cell
INSERT INTO `IM_cell` (`UNIQUE_CELL_ID`, `UNIQUE_CELL_NAME`, `TYPE`, `ORGAN`, `CPID`, `ANATOMY_ID`, `CELL_TYPE_ID`)
SELECT `UNIQUE_CELL_ID`, `UNIQUE_CELL_NAME`, `TYPE`, `ORGAN`, `CPID`, `ANATOMY_ID`, `CELL_TYPE_ID` 
FROM `CP_cell`;


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

INSERT INTO `IM_cell` VALUES
  (NULL, 1000000046, 'Resting Natural killer cell',             'Natural killer cell', 'Blood', NULL, NULL, 261),
  (NULL, 1000000047, 'Activated Natural killer cell',           'Natural killer cell', 'Blood', NULL, NULL, 261),
  (NULL, 1000000043, 'Resting Dendritic cell',                  'Dendritic cell',      'Blood', NULL, NULL, 32),
  (NULL, 1000000044, 'Activated Dendritic cell',                'Dendritic cell',      'Blood', NULL, NULL, 32),
  (NULL, 1000000054, 'Resting Mast cell',                       'Mast cell',           'Blood', NULL, NULL, 10),
  (NULL, 1000000055, 'Activated Mast cell',                     'Mast cell',           'Blood', NULL, NULL, 10);

-- cell_entity
insert into IM_cell_entity (ID)
select `CELL_ENTITY_ID` from IM_cell;
UPDATE IM_cell_entity SET ENTITY_TYPE='CELL';

-- echo "docker exec -it cbioDB1 sh -c \"mysql -ucbio1 -pP@ssword1 cbioportal1\" "
