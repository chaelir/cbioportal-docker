-- LICENSE_TBD --

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
--  Table structure for `CP_anatomy`
-- ----------------------------
DROP TABLE IF EXISTS `CP_anatomy`;
CREATE TABLE `CP_anatomy` (
  `ANATOMY_ID` varchar(255) NOT NULL,
  `Previous_Anatomy_ID` varchar(255) DEFAULT NULL,
  `Current_Anatomy_ID` varchar(255) DEFAULT NULL,
  `Body_Part` varchar(255) DEFAULT NULL,
  `Organ` varchar(255) DEFAULT NULL,
  `Sub_Organ` varchar(255) DEFAULT NULL,
  `Tissue_1` varchar(255) DEFAULT NULL,
  `Tissue_2` varchar(255) DEFAULT NULL,
  `Tissue_3` varchar(255) DEFAULT NULL,
  `Tissue_4` varchar(255) DEFAULT NULL,
  `Tissue_5_1` varchar(255) DEFAULT NULL,
  `Tissue_5_2` varchar(255) DEFAULT NULL,
  `Tissue_5_3` varchar(255) DEFAULT NULL,
  `Tissue_5_4` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ANATOMY_ID`),
  KEY `ANATOMY_ID` (`ANATOMY_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `CP_celltype`
-- ----------------------------
DROP TABLE IF EXISTS `CP_celltype`;
CREATE TABLE `CP_celltype` (
  `CELL_TYPE_ID` int(11) NOT NULL,
  `CELL_TYPE_NAME` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`CELL_TYPE_ID`),
  KEY `CELL_TYPE_ID` (`CELL_TYPE_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `CP_differentiated`
-- ----------------------------
-- ALTER TABLE IF EXISTS `CP_cell` DROP CONSTRAINT `cell_cx_anatomy`;
-- ALTER TABLE IF EXISTS `CP_cell` DROP CONSTRAINT `cell_cx_celltype`;
DROP TABLE IF EXISTS `CP_cell`;
CREATE TABLE `CP_cell` (
  `UNIQUE_CELL_ID` int(11) NOT NULL,
  `UNIQUE_CELL_NAME` varchar(255) NOT NULL,
  `TYPE` varchar(50) DEFAULT NULL,
  `ORGAN` varchar(64) DEFAULT NULL,
  `LENGTH` int(11) DEFAULT NULL,
  `ANATOMY_ID` varchar(255) DEFAULT NULL, 
   -- FOREIGN KEY
  `CELL_TYPE_ID` int(11) DEFAULT NULL,
   -- FOREIGN KEY
  `CPID` int(11) DEFAULT NULL,
  `Germ_Layer` varchar(255) DEFAULT NULL,
  `Differentiation_State` varchar(255) DEFAULT NULL,
  `Source_Age` varchar(255) DEFAULT NULL,
  `Raw_Anatomy_ID` varchar(255) DEFAULT NULL,
  `Raw_Cell_Type_ID` int(255) DEFAULT NULL,
  `Body_Part` varchar(255) DEFAULT NULL,
  `Sub_Organ` varchar(255) DEFAULT NULL,
  `Tissue_1` varchar(255) DEFAULT NULL,
  `Tissue_2` varchar(255) DEFAULT NULL,
  `Tissue_3` varchar(255) DEFAULT NULL,
  `Tissue_4` varchar(255) DEFAULT NULL,
  `Tissue_5_1` varchar(255) DEFAULT NULL,
  `Tissue_5_2` varchar(255) DEFAULT NULL,
  `Tissue_5_3` varchar(255) DEFAULT NULL,
  `Tissue_5_4` varchar(255) DEFAULT NULL,
  `Cell_Type_Name` varchar(255) DEFAULT NULL,
  `Cell_Type_Synonym` varchar(255) DEFAULT NULL,
  `Cell_Lineage_ID` varchar(255) DEFAULT NULL,
  `Uberon_ID` varchar(255) DEFAULT NULL,
  `Image_ID` varchar(255) DEFAULT NULL,
  `Tissue_Image_ID` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`UNIQUE_CELL_ID`),
  KEY `UNIQUE_CELL_NAME` (`UNIQUE_CELL_NAME`),
  CONSTRAINT `cell_cx_anatomy` FOREIGN KEY (`ANATOMY_ID`) REFERENCES `CP_anatomy` (`ANATOMY_ID`),
  CONSTRAINT `cell_cx_celltype` FOREIGN KEY (`CELL_TYPE_ID`) REFERENCES `CP_celltype` (`CELL_TYPE_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS = 0;

-- docker exec -it -e TZ=America/Los_Angeles -e MYSQL_USER=cbio1 -e MYSQL_PASSWORD=P@ssword1 cbioDB1 sh -c 'mysql -hcbioDB1 -ucbio1 -pP@ssword1 cbioportal1'
