/*
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
-- 2.5. Create IM_cell_alias like gene_alias:
--          Entrez_gene_id -> unique_cell_id
--					gene_alias -> cell_alias
*/

/* create necessary tables */

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `IM_cell`;
DROP TABLE IF EXISTS `IM_cell_entity`;
DROP TABLE IF EXISTS `IM_cell_profile`;
DROP TABLE IF EXISTS `IM_cell_alteration`;
DROP TABLE IF EXISTS `IM_cell_alias`;

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
  `UNIQUE_CELL_ID` int(11) NOT NULL DEFAULT -1,
  `UNIQUE_CELL_NAME` varchar(255) NOT NULL DEFAULT '',
  `CELL_ENTITY_ID` int(11) NOT NULL DEFAULT -1,
  `TYPE` varchar(50) DEFAULT NULL,
  `ORGAN` varchar(64) DEFAULT NULL,
  `LENGTH` int(11) DEFAULT NULL,
  PRIMARY KEY (`CELL_ENTITY_ID`),
  UNIQUE KEY `UNIQUE_CELL_ID` (`UNIQUE_CELL_ID`),
  KEY `UNIQUE_CELL_NAME` (`UNIQUE_CELL_NAME`),
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
--  Table structure for `IM_cell_alias`
-- ----------------------------
DROP TABLE IF EXISTS `IM_cell_alias`;
CREATE TABLE `IM_cell_alias` (
  `UNIQUE_CELL_ID` int(11) NOT NULL, 
  `CELL_ALIAS` varchar(255) NOT NULL,
  PRIMARY KEY (`UNIQUE_CELL_ID`,`CELL_ALIAS`),
  CONSTRAINT `cell_alias_ibfk_1` FOREIGN KEY (`UNIQUE_CELL_ID`) REFERENCES `IM_cell` (`UNIQUE_CELL_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
SET IM_cell.UNIQUE_CELL_ID = CP_differentiated.Cell_Type_ID;

UPDATE IM_cell
INNER JOIN CP_differentiated ON (IM_cell.Cell_Entity_ID = CONVERT(CP_differentiated.Cell_ID, SIGNED))
SET IM_cell.CELLPEDIA_CELL_TYPE_NAME = CP_differentiated.Cell_Type_Name;

UPDATE IM_cell
INNER JOIN CP_differentiated ON (IM_cell.Cell_Entity_ID = CONVERT(CP_differentiated.Cell_ID, SIGNED))
SET IM_cell.Organ = CP_differentiated.Organ;

UPDATE IM_cell SET TYPE='DIFFERENTIATED';

/* add entries that are supplementary to CP database */

/*
# Known issues:
# these assignments are only temporary (Cellpedia_Cell_Type_ID)
# No TCM vs TEM subpopulation, all assumed to be TCM
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
INSERT INTO `IM_cell_entity` VALUES 
  (1000000046, 'CELL'),
  (1000000047, 'CELL'),
  (1000000043, 'CELL'),
  (1000000044, 'CELL'),
  (1000000054, 'CELL'),
  (1000000055, 'CELL');

INSERT INTO `IM_cell` VALUES 
  (261, 'Resting Natural killer cell', 1000000046, 'DIFFERENTIATED', 'Blood', NULL), 
  (261, 'Activated Natural killer cell', 1000000047, 'DIFFERENTIATED', 'Blood', NULL), 
  (32, 'Resting Dendritic cell', 1000000043, 'DIFFERENTIATED', 'Blood', NULL), 
  (9, 'Activated Dendritic cell', 1000000044, 'DIFFERENTIATED', 'Blood', NULL), 
  (54, 'Resting Mast cell', 1000000054, 'DIFFERENTIATED', 'Blood', NULL), 
  (54, 'Activated Mast cell', 1000000055, 'DIFFERENTIATED', 'Blood', NULL);

-- echo "docker exec -it cbioDB1 sh -c \"mysql -ucbio1 -pP@ssword1 cbioportal1\" "
