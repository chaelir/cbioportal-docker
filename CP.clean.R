#!/usr/bin/env Rscript

#The way to maintain CP database is now manual
#The process involve keeping three raw csv sheets updated with cellpedia by cellpedia_init.sh
#   1. cellpedia.anatomy.csv
#   2. cellpedia.celltype.csv
#   3. cellpedia.differentiated.txt
# these sheets need to be cleaned in R by CP.clean.R and add necessary columns such that
#   the resulting CP_*.txt are importatble as data to CP tables (for now only differentiated cells)
#   1. CP_anatomy.csv
#   2. CP_celltype.csv
#   3. CP_cell.csv

library(readr)
library(dplyr)
library(tibble)

### import raw csv data as the output of scrambler cellpedia_init.sh
cellpedia_anatomy <- read_csv("~/setup/cbioportal-docker/archive/cellpedia.anatomy.csv", 
  col_types = cols(`Current Anatomy ID` = col_character(), 
  `Sub-organ` = col_character(), `Tissue 5-2` = col_character(), 
  `Tissue 5-3` = col_character(), `Tissue 5-4` = col_character()))
cellpedia_celltype <- read_csv("~/setup/cbioportal-docker/archive/cellpedia.celltype.csv",
  col_types = cols(Cell_ID = col_integer()))
cellpedia_differentiated <- read_csv("~/setup/cbioportal-docker/archive/cellpedia.differentiated.csv", 
  col_types = cols(`Anatomy Id` = col_character(), 
  `Cell Type Id` = col_integer(), No. = col_integer(), 
  `Sub-organ` = col_character(), Synonym = col_character(), 
  `Tissue 1` = col_character(), `Tissue 2` = col_character(), 
  `Tissue 3` = col_character(), `Tissue 4` = col_character(), 
  `Tissue 5-1` = col_character(), `Tissue 5-2` = col_character(), 
  `Tissue 5-3` = col_character(), `Tissue 5-4` = col_character(), 
  `Tissue Image ID` = col_character(), 
  `UBERON Id` = col_character()))
### Some imports have warnings but worked fine! ###

### prepare CP tables that intereact with IM tables (at no loss of cellpedia information)
#CP_anatomy
# `ANATOMY_ID` is primary key and unique
CP_anatomy = tibble::tibble(ANATOMY_ID=cellpedia_anatomy$`Current Anatomy ID`)
CP_anatomy = cbind(CP_anatomy, cellpedia_anatomy)
colnames(CP_anatomy)
CP_anatomy = CP_anatomy %>% 
  dplyr::group_by(ANATOMY_ID) %>% 
  summarise(`Previous Anatomy ID` = paste(unique(`Previous Anatomy ID`), collapse="|"),
            `Current Anatomy ID` = paste(unique(`Current Anatomy ID`), collapse="|"),
            `Body part` = paste(unique(`Body part`), collapse="|"),
            `Organ` = paste(unique(`Organ`), collapse="|"),
            `Sub-organ` = paste(unique(`Sub-organ`), collapse="|"),
            `Tissue 1` = paste(unique(`Tissue 1`), collapse="|"),
            `Tissue 2` = paste(unique(`Tissue 2`), collapse="|"),
            `Tissue 3` = paste(unique(`Tissue 3`), collapse="|"),
            `Tissue 4` = paste(unique(`Tissue 4`), collapse="|"),
            `Tissue 5-1` = paste(unique(`Tissue 5-1`), collapse="|"),
            `Tissue 5-2` = paste(unique(`Tissue 5-2`), collapse="|"),
            `Tissue 5-3` = paste(unique(`Tissue 5-3`), collapse="|"),
            `Tissue 5-4` = paste(unique(`Tissue 5-4`), collapse="|"))
# colnames(CP_anatomy)
# [1] "ANATOMY_ID"          "Previous Anatomy ID" "Current Anatomy ID"  "Body part"           "Organ"              
# [6] "Sub-organ"           "Tissue 1"            "Tissue 2"            "Tissue 3"            "Tissue 4"           
# [11] "Tissue 5-1"          "Tissue 5-2"          "Tissue 5-3"          "Tissue 5-4"
stopifnot(assertthat::are_equal(length(CP_anatomy$ANATOMY_ID), length(unique(CP_anatomy$ANATOMY_ID))))


#CP_celltype
# `CELL_TYPE_ID` is primary key and unique
# `CELL_TYPE_NAME` is key and unique
# apply a patch that only first cell_type_id of the same cell_type_name remains
colnames(cellpedia_celltype)
CP_celltype = cellpedia_celltype %>% 
  dplyr::group_by(Cell_ID) %>% 
  dplyr::summarise(Cell_Name = paste(`Cell name`, collapse="|"))
CP_dups = CP_celltype %>%
  dplyr::group_by(Cell_Name) %>%
  dplyr::filter( n()>1 ) %>%
  dplyr::mutate( name_count = sequence(n())) %>%
  dplyr::mutate( True_Cell_ID = Cell_ID[1] )
CP_celltype = CP_celltype %>%
  dplyr::group_by(Cell_Name) %>%
  dplyr::mutate( name_count = sequence(n())) %>%
  dplyr::filter( name_count == 1 ) %>%
  dplyr::mutate( CELL_TYPE_ID = Cell_ID ) %>%
  dplyr::mutate( CELL_TYPE_NAME = Cell_Name ) %>%
  dplyr::ungroup() %>%
  dplyr::select( -c(Cell_ID, Cell_Name, name_count) )
stopifnot(assertthat::are_equal(length(CP_celltype$CELL_TYPE_ID), length(unique(CP_celltype$CELL_TYPE_ID))))
stopifnot(assertthat::are_equal(length(CP_celltype$CELL_TYPE_NAME), length(unique(CP_celltype$CELL_TYPE_NAME))))


# CP_cell
# CPID is primary key and unique;
# UNIQUE_CELL_ID is unique; 
# UNIQUE_CELL_NAME is unique;
# `Anatomy Id` is a foreign key to CP_anatomy
# ``
# CPID is unique
# replace CP_dups$Cell_ID by CP_dups$True_Cell_ID

#replace the Cell Type Id by its first occurrence of the same name (CP_dups)
#which(!is.na(match(cellpedia_differentiated$`Cell Type Id`, CP_dups$Cell_ID)))
cellpedia_differentiated$`Cell Type Id` = 
  ifelse(is.na(match(cellpedia_differentiated$`Cell Type Id`, CP_dups$Cell_ID)),
               cellpedia_differentiated$`Cell Type Id`,
               CP_dups$True_Cell_ID[match(cellpedia_differentiated$`Cell Type Id`, CP_dups$Cell_ID)]) 
CP_cell = tibble::tibble(CPID = cellpedia_differentiated$No.)
CP_cell$UNIQUE_CELL_ID = CP_cell$CPID
CP_cell$UNIQUE_CELL_NAME = paste(cellpedia_differentiated$`Cell Type`, " CPID=", CP_cell$CPID, sep='')
CP_cell$TYPE = cellpedia_differentiated$`Cell Type`
CP_cell$ORGAN = cellpedia_differentiated$`Organ`
CP_cell$LENGTH = NA
CP_cell$ANATOMY_ID = cellpedia_differentiated$`Anatomy Id`
CP_cell$CELL_TYPE_ID = cellpedia_differentiated$`Cell Type Id`
CP_cell = cbind(CP_cell, cellpedia_differentiated)
CP_cell = CP_cell %>%
  filter(ANATOMY_ID %in% CP_anatomy$ANATOMY_ID) %>%
  filter(CELL_TYPE_ID %in% CP_celltype$CELL_TYPE_ID) %>%
  select(-c(CPID)) %>%
  plyr::rename(c("No." = "CPID")) %>%
  plyr::rename(c("Anatomy Id" = "Raw Anatomy Id")) %>%
  plyr::rename(c("Cell Type Id" = "Raw Cell Type Id")) %>%
  select(-c(Organ))
  
# remove inconsistent entries 
# sel=!CP_cell$ANATOMY_ID %in% CP_anatomy$ANATOMY_ID
# CP_cell[sel,]
# sel=!CP_cell$CELL_TYPE_ID %in% CP_celltype$CELL_TYPE_ID
# CP_cell[sel,]
stopifnot(assertthat::are_equal(length(CP_cell$UNIQUE_CELL_ID), length(unique(CP_cell$UNIQUE_CELL_ID))))
stopifnot(assertthat::are_equal(length(CP_cell$UNIQUE_CELL_NAME), length(unique(CP_cell$UNIQUE_CELL_NAME))))
stopifnot(all(CP_cell$ANATOMY_ID %in% CP_anatomy$ANATOMY_ID))
stopifnot(all(CP_cell$CELL_TYPE_ID %in% CP_celltype$CELL_TYPE_ID))

#write mysql importable tables
write.table(CP_cell, file='~/setup/cbioportal-docker/cellpedia/CP_cell.csv', 
            quote = F, col.names = T, row.names = F, sep=',')
write.table(CP_celltype, file='~/setup/cbioportal-docker/cellpedia/CP_celltype.csv', 
            quote = F, col.names = T, row.names = F, sep=',')
write.table(CP_anatomy, file='~/setup/cbioportal-docker/cellpedia/CP_anatomy.csv', 
            quote = F, col.names = T, row.names = F, sep=',')
# these CP csv files will be used to populate CP tables and dumped to cellpedia.dump.sql

