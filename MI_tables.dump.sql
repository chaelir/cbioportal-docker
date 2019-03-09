-- 1.1. Create IM_microbe_profile like genetic_profile:
--          genetic_profile_id -> microbe_profile_id,
--          genetic_alteration_type -> microbe_alteration_type,
--          stable_id,
--          cancer_study_id,
--          data_type,
--          name,
--          description
-- 1.2. Create IM_microbe_alteration like genetic_alteration:
--          genetic_profile_id -> microbe_profile_id
--          genetic_entity_id -> microbe_entity_id
-- 1.3. Create IM_microbe_entity like genetic_entity:
--          ID(BS.taxon.taxon_id) -> MICROBE
-- 1.4. Create IM_microbe like gene
--          Entrez_gene_id -> ncbi_taxon_id (i.e. BS.taxon.ncbi_taxon_id) - unique
--          Hugo_gene_symbol -> ncbi_taxon_name (i.e. BS.taxon.ncbi_taxon_name) - unique
--          genetic_entity_id -> microbe_entity_id (i.e. BS.taxon.taxon_id) - unique
--          cytoband -> taxon_level (i.e. BS.taxon.node_rank) ?
--          type : bacteria / archae
--          length,
-- 2.1. Create IM_cell_entity like genetic_entity:
--          ID (CP.differentiated.cell_id) -> CELL
-- 2.1. Create IM_cell like gene
--          Entrez_gene_id -> cellpedia_cell_id (i.e. CP.celltype.cell_type_id) - non-unique
--          Hugo_gene_symbol -> cellpedia_cell_name (i.e. CP.celltype.cell_type_name) - non-unique
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

DROP TABLE IF EXISTS `IM_microbe`;
DROP TABLE IF EXISTS `IM_microbe_profile`;
DROP TABLE IF EXISTS `IM_microbe_alteration`;
DROP TABLE IF EXISTS `IM_microbe_entity`;
DROP TABLE IF EXISTS `IM_cell`;
DROP TABLE IF EXISTS `IM_cell_profile`;
DROP TABLE IF EXISTS `IM_cell_alteration`;
DROP TABLE IF EXISTS `IM_cell_entity`;





