# LICENSE_TBD #

### this script prepares the cgds_im.sql file ###

#the cgds_im.sql expands the cgds.sql seed DB
#the script requires git 
#the script temporary creates a cgds_im

#show script commands
set -x

### 0. configurable variables and dependency installation
biosql_init_sql="../db_BS/BS_tables.init.sql"
cellpedia_init_sql="../db_CP/CP_tables.init.sql"
im_cell_init_sql="IM_cell.init.sql"
im_microbe_init_sql="IM_microbe.init.sql"
mysql_root_password="password"
#mysql_cgds_im_user="cgds_im_user"
#mysql_cgds_im_password="password"

### 1. Creat the cgds_im dababase in mysql
#===========================================
mysql -uroot -p${mysql_root_password} -ve "DROP DATABASE IF EXISTS cgds_im; CREATE DATABASE cgds_im"
mysql -uroot -p${mysql_root_password} -ve "DROP USER IF EXISTS 'cgds_im_user'@'localhost'; CREATE USER 'cgds_im_user'@'localhost' IDENTIFIED BY 'password'"
mysql -uroot -p${mysql_root_password} -ve "GRANT ALL PRIVILEGES ON *.* TO 'cgds_im_user'@'localhost' IDENTIFIED BY 'password'"
mysql -uroot -p${mysql_root_password} -ve "FLUSH PRIVILEGES"

### 2. Import and configure component databases
#===========================================
mysql -ucgds_im_user -ppassword cgds_im < ${biosql_init_sql}
mysql -ucgds_im_user -ppassword cgds_im < ${cellpedia_init_sql}
#NOTE: the LOCAL keyword is important to avoid access denied issue for loading.
mysql -ucgds_im_user -ppassword cgds_im -ve "
    LOAD DATA LOCAL INFILE '../db_CP/CP_anatomy.csv'
    INTO TABLE CP_anatomy
    FIELDS TERMINATED BY ','
    LINES TERMINATED BY '\n'
    IGNORE 1 ROWS;"
mysql -ucgds_im_user -ppassword cgds_im -ve "
    LOAD DATA LOCAL INFILE '../db_CP/CP_celltype.csv'
    INTO TABLE CP_celltype
    FIELDS TERMINATED BY ','
    LINES TERMINATED BY '\n'
    IGNORE 1 ROWS;"
mysql -ucgds_im_user -ppassword cgds_im -ve "
    LOAD DATA LOCAL INFILE '../db_CP/CP_cell.csv'
    INTO TABLE CP_cell
    FIELDS TERMINATED BY ','
    LINES TERMINATED BY '\n'
    IGNORE 1 ROWS;"
#NOTE: init of im tables must follow populating cp tables
mysql -ucgds_im_user -ppassword cgds_im < ${im_cell_init_sql}
#TODO: microbe tables
#mysql -ucgds_im_user -ppassword cgds_im < ${im_microbe_init_sql}

### 3. Export only the IM database into a sql file
#===========================================
mysqldump --skip-extended-insert --skip-add-locks -ucgds_im_user -ppassword cgds_im IM_cell_entity IM_cell IM_cell_profile IM_cell_alteration IM_cell_alias | sed -e "s/\\\'/''/g" > cgds_im.sql
#NOTE: b/c of dependency table dumping order is important. A simply dump like the following does not work!
#NOTE: add --skip-add-locks to avoid LOCK/UNLOCK statements in the dumped sql
#NOTE: the sed command is to resolve the /' that dump escape ' in value, make it ANSI SQL and importable by JDBC
#mysql -uroot -p${mysql_root_password} -N information_schema -e "select table_name from tables where table_schema = 'cgds_im' and table_name like 'IM_%'" > IM_tables.lst 
#mysqldump -ucgds_im_user -ppassword cgds_im `cat IM_tables.lst` > cgds_im.sql
cp cgds_im.sql cbioportal/db-scripts/src/main/resources # this one should go to other scripts, later
#this seed DB is required for any further testing 
#e.g. debugging CancerTypeMyBatisRepositoryTest with file origifinal from db-scripts
#cbio.maven.sh test master
#cbio.maven.sh clean persistence-mybatis 
#cbio.maven.sh compile persistence-mybatis
#cbio.maven.sh test persistence-mybatis -Dtest=CancerTypeMyBatisRepositoryTest
