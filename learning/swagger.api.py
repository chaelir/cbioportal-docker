#!/usr/bin/env python3

### reproduce example in https://github.com/cBioPortal/cbioportal/blob/master/docs/The-API-and-API-Client-%5BBeta%5D.md
# to do this, first load gbm_tcga to your cbioportal running at http://localhost:8882/cbioportal
from bravado.client import SwaggerClient
cbioportal = SwaggerClient.from_url('http://localhost:8882/cbioportal/api/api-docs')
dir(cbioportal)
# you can rename to save typing
c = cbioportal
for a in dir(c):
    c.__setattr__(a.replace(' ', '_').lower(), cbioportal.__getattr__(a))

r = c.Mutations.getMutationsInMolecularProfileBySampleListIdUsingGET(
    molecularProfileId='gbm_tcga_mutations', sampleListId="gbm_tcga_all", projection="DETAILED")
r.result()
len(r.result())

### now reproduce all swgger-ui.html cancer types examples
r = c.Cancer_Types.getAllCancerTypesUsingGET()
print(r.result())
r = c.Cancer_Types.getCancerTypeUsingGET(cancerTypeId='gbm')
print(r.result())
# you can list all available subapis by:
dir(c.Cancer_Types)

### some mock olecular data examples
# to do this, you need to manually add a few things in the backend database.
# insert into `cbioportal`.`genetic_profile` ( `STABLE_ID`, `CANCER_STUDY_ID`, `GENETIC_ALTERATION_TYPE`, `DATATYPE`, `NAME`, `DESCRIPTION`, `SHOW_PROFILE_IN_ANALYSIS_TAB`)
#                                  values ( 'gbm_tcga_cell_values', '1', 'COPY_NUMBER_ALTERATION', 'DISCRETE', 'Mock cell values', 'Mock cell values', '1');
## this auto id should be 16
# insert into `cbioportal`.`genetic_entity` ( `ENTITY_TYPE`) values ( 'CELL');
## this auto id should be 1000001, if not, change it to 1000001
# insert into `cbioportal`.`genetic_alteration` ( `GENETIC_PROFILE_ID`, `GENETIC_ENTITY_ID`, `VALUES`) values ( '16', '1000001', '0,1');
# insert into `cbioportal`.`genetic_alteration` ( `GENETIC_PROFILE_ID`, `GENETIC_ENTITY_ID`, `VALUES`) values ( '16', '9', '0.9,0.9');
# insert into `cbioportal`.`genetic_alteration` ( `GENETIC_PROFILE_ID`, `GENETIC_ENTITY_ID`, `VALUES`) values ( '16', '1', '0.1,0.1');
# insert into `cbioportal`.`genetic_profile_samples` ( `GENETIC_PROFILE_ID`, `ORDERED_SAMPLE_LIST`) values ( '16', '1,2');
## also notice in the gene table:
# ENTREZ_GENE_ID	HUGO_GENE_SYMBOL	GENETIC_ENTITY_ID	TYPE	CYTOBAND	LENGTH
# 1	A1BG	1	protein-coding	19q13.43	0
# 9	NAT1	4	protein-coding	8p22	0
## also notice in the sample table:
# INTERNAL_ID	STABLE_ID	SAMPLE_TYPE	PATIENT_ID	TYPE_OF_CANCER_ID
# 1	TCGA-02-0001-01	Primary Solid Tumor	1	gbm
# 2	TCGA-02-0003-01	Primary Solid Tumor	2	gbm

dir(c.Molecular_Data)
# you can print the __doc__ string to see the parameters allowed
print(c.Molecular_Data.fetchAllMolecularDataInMolecularProfileUsingPOST.__doc__)
# [POST] Fetch molecular data in a molecular profile
# :param molecularProfileId: Molecular Profile ID e.g. acc_tcga_rna_seq_v2_mrna
# :type molecularProfileId: string
# :param molecularDataFilter: List of Sample IDs/Sample List ID and Entrez Gene IDs
# :type molecularDataFilter: #/definitions/MolecularDataFilter
# :param projection: Level of detail of the response (Default: SUMMARY) (optional)
# :type projection: string
# :returns: 200: OK
# :rtype: array:#/definitions/NumericGeneMolecularData
# QUIZ: where to find #/definitions/MolecularDataFilter within python?
# for now, let's just copy from swagger-ui.html
# MolecularDataFilter{
#   entrezGeneIds	[...]
#   sampleIds	[...]
#   sampleListId	string
# }
# only one of sampleIds or sampleListId is allowed, let's try sampleIds first
r = c.Molecular_Data.fetchAllMolecularDataInMolecularProfileUsingPOST(
    molecularProfileId = 'gbm_tcga_cell_values',
    molecularDataFilter = { 'entrezGeneIds' : [ 1 ], 'sampleIds' : [ 'TCGA-02-0001-01' ] })
print(r.result())
# expected value 0.1 as we set in the genetic_alteration table
# Let's try sampleListId
r = c.Molecular_Data.fetchAllMolecularDataInMolecularProfileUsingPOST(
    molecularProfileId = 'gbm_tcga_cell_values',
    molecularDataFilter = { 'entrezGeneIds' : [ 1 ], 'sampleListId' : "gbm_tcga_all" })
print(r.result())
# expected values are 0.1 and 0.1 as we set in the genetic_alteration table for the first two samples

### QUIZ: test other apis of molecular data and find the limits
# one limit I found is it requires using entrezGeneId, which our cell and microbe data would not have
# how to bypass this?
# we probbably first locate where these POST/GET functions were implemented
dir(c.Molecular_Data)
# grep -lrnw cbioportal -e 'fetchAllMolecularDataInMolecularProfileUsingPOST'
# grep -lrnw cbioportal -e 'fetchMolecularDataInMultipleMolecularProfilesUsingPOST'
# grep -lrnw cbioportal -e 'getAllMolecularDataInMolecularProfileUsingGET'
# you will find
#  1. cbioportal/portal/reactapp/main.app.js as the the javascript file forming url post/get
#  2. cbioportal/service/src/main/java/org/cbioportal/service/*.java files are element java classes responding to these requests
#  3. cbioportal/web/src/test/java/org/cbioportal/web/*.java files are elementary tests of these services.
# grep -lrnw cbioportal -e 'getGeneMolecularAlterationsInMultipleMolecularProfiles'
# now you see
#  3. cbioportal/persistence/persistence-mybatis/src/main/java/org/cbioportal/persistence/mybatis/*.java were used by element classes
### QUIZ: where these functions actually interact with database? a lot of them are only interface declaration, where are the bodies?
# you will find the actualy implementation in .xml files here:
#  4. cbioportal/persistence/persistence-mybatis/src/main/resources/org/cbioportal/persistence/*.xml
# it is using a mybatis technique https://blog.mybatis.org
### QUIZ: how to add new apis read generic profile data not restricted  by entrezId/hugoSymbols
# lots of effort in sequence
#  * adapt several xml files to complete the database interaction
#  * adapt some mybatis/*.java files to provide these interactions in interface
#  * adapt some service/*.java files to serve these interaction requests
#  * adapt some test/../web/*.java files to complete tests for these interaction requests
### QUIZ: how to add these new apis to swagger-ui.html?
