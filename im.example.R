library(readr)

# 640 samples x 25 features
data_bcr_clinical_data_sample <- read_delim("~/setup/cbioportal-docker/example/data_bcr_clinical_data_sample.txt", 
                                            "\t", escape_double = FALSE, comment = "#", 
                                            trim_ws = TRUE)

cibersort_raw <- read_csv("~/setup/cbioportal-docker/cibersort.csv")
#View(cibersort_raw)
cibersort_clean = cibersort_raw %>% mutate(SampleID = substring(SampleID, 1,16)) %>%
  mutate(SampleID = gsub("\\.","-",SampleID)) %>%
  dplyr::select(-c("CancerType","P.value","RMSE","Correlation"))
cell_raw_names = colnames(cibersort_clean)[-1]
cell_im_ids = c(4, 2, 16, 
                39, 23, 33, 
                35, 31, 38, 
                40, 1000000046, 1000000047, 
                13, 9, 10, 
                11, 1000000043, 1000000044, 
                1000000054, 1000000055, 6,
                15)
cell_im_names = c('Naive B cell', 'Memory B cell', 'Plasma cell', 
                'CD8+ cytotoxic T lymphocyte', 'Naive CD4+ T cell', 'Central CD4+ memory T (Tcm) cell', 
                'Effector CD4+ memory T (Tem) cell', 'Follicular helper (Tfh) T cell', 'Regulatory T (Treg) cell', 
                'Gamma delta T cell', 'Resting Natural killer cell', 'Activated Natural killer cell', 
                'Monocyte', 'M0 Macrophage', 'M1 macrophage', 
                'M2 macrophage', 'Resting Dendritic cell', 'Activated Dendritic cell', 
                'Resting Mast cell', 'Activated Mast cell', 'Eosinophil',
                'Neutrophil')
colnames(cibersort_clean) = c('Sample_ID', cell_im_ids)
cibersort_export = tibble::as_tibble(t(cibersort_clean[,2:ncol(cibersort_clean)])) # 546 samples
colnames(cibersort_export) = substr(cibersort_clean$Sample_ID, 1, 15) # TCGA-DM-A28E-01
cibersort_export = cibersort_export[, !duplicated(colnames(cibersort_export))] # 462 samples, if name collide just pick the first ones
cibersort_export = cibersort_export[, colnames(cibersort_export) %in% data_bcr_clinical_data_sample$SAMPLE_ID ] # 473 samples, if name not found, ignore
cibersort_index = tibble::as_tibble( list( 
    Cell_Entity_ID = cell_im_ids,
    Cellpedia_Cell_Type_Name = gsub(' ', '_', cell_im_names)
))
cibersort_export = cbind(cibersort_index, cibersort_export)
write.table(cibersort_export, file='~/setup/cbioportal-docker/example/testing/data_linear_CRA.txt', 
            quote = F, col.names = T, row.names = F, sep='\t')
# 1. create example/meta_linear_CRA.txt;
# 2. create example/meta_linear_MRA.txt;
# 3. apply patches to cbioportal/core/src/main/scripts/importer/*

grammy_raw <- read_csv("~/setup/cbioportal-docker/guo_results_sum.csv")
grammy_sample_ids = stringr::str_extract(grammy_raw$ID, "TCGA-.{2}-.{4}-.{2}") #TCGA-AA-3516-01
microbe_im_ids = colnames(grammy_raw)[1:(ncol(grammy_raw)-1)]
grammy_export = tibble::as_tibble(t(grammy_raw[,1:(ncol(grammy_raw)-1)])) #254 samples
colnames(grammy_export) = grammy_sample_ids
grammy_export = grammy_export[, !duplicated(grammy_sample_ids)] #204 samples, if name collide just pick the first ones
grammy_export = grammy_export[, colnames(grammy_export) %in% data_bcr_clinical_data_sample$SAMPLE_ID] #113 samples
grammy_index = tibble::as_tibble( list( 
  NCBI_Taxonomy_ID = microbe_im_ids
))
grammy_export = cbind(grammy_index, grammy_export)              #205 samples
write.table(grammy_export, file='~/setup/cbioportal-docker/example/testing/data_linear_MRA.txt', 
            quote = F, col.names = T, row.names = F, sep='\t')


# in IM_cell and IM_microbe, 
# we must require NCBI_TAXON_NAME and NCBI_TAXON_ID fields unique

### CP DEBUG PROCESS (DATA LOADING):
# 1. fix existing MI_cell table 
#   1.1 rename CELLPEDIA_CELL_TYPE_NAME -> UNIQUE_CELL_NAME; use _ concatenated name
#   1.2 rename CELLPEDIA_CELL_TYPE_ID -> UNIQUE_CELL_ID; use x100+subs
#   1.3 TYPE should contain current CELLPEDIA_CELL_TYPE_ID
# 2. add cell_alias table
#   2.1 cell_alias
# 3. visually check all modified files
#   3.1 check model/*Cell*.java: 
#       CanonicalCell.java       Cell.java                CellAlterationType.java  CellProfile.java
# 4. scripts/ImportCellProfileData.java
#   4.1 check it, compile it with libraries in model
#   4.2 run it and check database change
# 5. try scripts/metaImport.py
#   5.1 run it and check database change

### DEBUG PROCESS (DATA PRESENTATION):
# 1. add a Cell Composition view http://localhost:8881/cbioportal/study?id=coadread_tcga#cra
# 2. add a Microbe Composition view http://localhost:8881/cbioportal/study?id=coadread_tcga#mra
# 3. Cell_Name | Organ | Mean | SD | Presence | P-P index (at least P in P samples)

# ImportRelaProfileData.java
# what is this file, should just ignore

### Files changed / created:
# /core/src/main/java/org/mskcc/cbio/portal/scripts/
#    ImportProfileData.java -> ImportCellProfileData.java
#    ExportProfileData.java -> ExportCellProfileData.java
# /core/src/main/java/org/mskcc/cbio/portal/dao/
#    DaoGeneticAlteration.java -> DaoCellAlteration.java [OK]
#    DaoGeneticProfile.java -> DaoCellProfile.java [OK]
#    DaoGeneticEntity.java -> DaoCellEntity.java [OK]
#    DaoGene.java -> DaoCell.java [OK]
#    DaoGeneOptimized.java -> DaoCellOptimized.java
# /core/src/main/java/org/mskcc/cbio/portal/model/
#    GeneticProfile.java -> CellProfile.java [OK]
#    Gene.java -> Cell.java [OK]
#    CanonicalGene.java -> CanonicalCell.java [OK]
#    GeneticAlterationType.java -> GeneticAlterationType.java [OK]
# /core/src/main/resources/
#    touch cbio_cancer_cells.txt [OK]
#    touch cell_symbol_disambiguation.txt [OK]

### replace symbols, order is importaant!!!!
### Variable/Functions changed
### scripts/ImportCellProfileData.java
#    *GeneticAlteration* -> *CellAlteration*
#    *GeneticProfile* -> *CellProfile*
#    *geneticProfile* -> *cellProfile*
#    *genePanel* -> *cellPanel*
#    *entrezGeneId* -> *InputCellEntityId* # stays as an avatar of cellEntityId, to reduce coding change
#    *geneticEntityId* -> *cellEntityId*
#    *genetic_alteration* -> *IM_cell_alteration*
#    %s/GENETIC_PROFILE_ID/CELL_PROFILE_ID/g
#    %s/GENETIC_ENTITY_ID/CELL_ENTITY_ID/g
#    %s/ENTREZ_GENE_ID/CELLPEDIA_CELL_TYPE_ID/g
#    %s/HUGO_GENE_SYMBOL/CELLPEDIA_CELL_TYPE_NAME/g
#    *DaoGeneOptimized* -> remove all lines, as no ID translation needed or permitted
#    *getGenesInProfile* or *CanonicalGene* -> remove all lines, as not involving gene
### model/CanonicalCell.java ###
#    %s/entrezGeneId/inputCellTypeId/g
#    %s/hugoGeneSymbol/inputCellTypeName/g
#    %s/Genetic/Cell/g
#    %s/genetic/cell/g
#    %s/Gene/Cell/g
#    %s/gene/cell/g
#    %s/Cytoband/Organ/g
#    %s/cytoband/organ/g
#    %s/EntrezCellId/InputCellTypeId/g
#    %s/HugoCellSymbol/InputCellTypeName/g
### doa/DaoCell.java ###
#    %s/WithoutInputCellTypeId/WithoutCellEntityId/g
#    %s/CanonicalGene/CanonicalCell/g
#    %s/Genetic/Cell/g
#    %s/genetic/cell/g
#    %s/Gene/Cell/g
#    %s/gene/cell/g
#    %s/CYTOBAND/ORGAN/g
#    %s/Cytoband/Organ/g
#    %s/cytoband/organ/g
#    %s/EntrezCellId/InputCellTypeId/g
#    %s/HugoCellSymbol/InputCellTypeName/g
#    %s/entrezCellId/inputCellTypeId/g
#    %s/hugoCellSymbol/inputCellTypeName/g
#    %s/ENTREZ_GENE_ID/CELLPEDIA_CELL_TYPE_ID/g
#    %s/HUGO_GENE_SYMBOL/CELLPEDIA_CELL_TYPE_NAME/g
#    %s/EntrezId/CellEntityId/g
#    %s/entrezId/cellEntityId/g
#    %s/INTO cell/INTO IM_cell/g
#    %s/UPDATE cell/UPDATE IM_cell/g
### dao/DaoCellEntity.java ###
#    %s/GeneticEntity/CellEntity/g
#    %s/genetic/cell/g
#    %s/DaoGene.class/DaoCell.class/g
#    %s/FROM cell/FROM IM_cell/g
### model/CellProfile.java
#    %s/Genetic/Cell/g
#    %s/genetic/cell/g
### model/CellAlterationType.java
#    %s/Genetic/Cell/g
#    CELL_RELATIVE_ABUNDANCE
### dao/DaoCellProfile.java
#    %s/Genetic/Cell/g
#    %s/cell_profile/IM_cell_profile/g
#    %s/GENETIC_PROFILE_ID/CELL_PROFILE_ID/g
#    %s/GENETIC_ALTERATION_TYPE/CELL_ALTERATION_TYPE/g
### dao/DaoCellAlteration.java
#    %s/CanonicalGene/CanonicalCell/g
#    %s/Genes/Cells/g
#    %s/geneList/cellList/g
#    %s/DaoGeneOptimize/DaoCellOptimize/g
#    %s/daoGene/daoCell/g
#    %s/Gene/Cell/g
### dao/DaoCellOptimized.java
#    %s/genetic/cell/g
#    %s/Genetic/Cell/g
#    %s/Gene/Cell/g
#    %s/GENES/CELLS/g
#    %s/genes/cells/g
#    %s/gene/cell/g
#    %s/GENE/CELL/g
#    %s/entrezIdMap/inputCellTypeIdMap/g
#    %s/getEntrezCellId/getCellEntityId/g
#    %s/EntrezCellId/CellEntityId/g
#    %s/entrezCellId/cellEntityId/g
#    %s/getHugoCellSymbolAllCaps/getInputCellTypeNameAllCaps/g
#    %s/hugoCellSymbol/inputCellTypeName/g


# Now, involving other files
# org.mskcc.cbio.portal.model.CanonicalGene;
# Fix other potential dependent changes.
# Need to do the same for Microbes afterwards




