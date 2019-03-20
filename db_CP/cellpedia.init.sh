#!/bin/bash
set -x
stage=$1

if [ $stage == "get_cp" ]; then 
  cd archive
  #get necessary commandline tools
  brew install html-xml-utils #for htmlutils on mac: https://www.w3.org/Tools/HTML-XML-utils/README
  brew install gnumeric #for convert xlsx to csv on mac: http://www.gnumeric.org
  #download CP database tables
  wget http://shogoin.stemcellinformatics.org/assets/SHOGoiNCellTaxonomy_assignedIDs_AnatomyID.xlsx \
    -O cellpedia.anatomy.xlsx
  wget http://shogoin.stemcellinformatics.org/assets/SHOGoiNCellTaxonomy_assignedIDs_CellTypeID.xlsx \
    -O cellpedia.celltype.xlsx
  # curl -s http://shogoin.stemcellinformatics.org/cell/homo_sapiens | hxselect table <table>Example Domain</title>
  # we are dealing with a not well formed html
  curl -silent http://shogoin.stemcellinformatics.org/cell/homo_sapiens | \
    sed -n '/id="tab-differentiated"/,$p' | \
    sed '\=</div={q;}' | \ 
    hxselect table >cellpedia.differentiated.html
  
  # convert to standard csv files to imported to mysql
  ssconvert -T Gnumeric_stf:stf_assistant \
    -O 'separator=, format=raw quoting-mode=never' \
    cellpedia.anatomy.xlsx cellpedia.anatomy.csv # this table used parenthesis in column name
  sed -i -e '1,1s/([^()]*)//g' cellpedia.anatomy.csv # fix it!
  ssconvert -T Gnumeric_stf:stf_assistant \
    -O 'separator=, format=raw quoting-mode=never' \
    cellpedia.celltype.xlsx cellpedia.celltype.csv
  #ssconvert failed to perserve ID numbers as string
  cp cellpedia.differentiated.html cellpedia.differentiated.xls
  ssconvert -T Gnumeric_stf:stf_assistant \
    -O 'separator=; format=raw quoting-mode=never' \
    cellpedia.differentiated.xls cellpedia.differentiated.txt # this table used semi colon seperated values
  sed 's/,/ /g' cellpedia.differentiated.txt | sed 's/;/,/g' >cellpedia.differentiated.csv # fix it! 
  #MANUAL: load cellpedia.differentiated.csv in MS excel, correct the header rows and anatomy id and save it
  cd ..
fi

### testing if CP could be created correctly
if [ $stage == "test_cp" ]; then 
  #mysql_root_password="password"
  #CP_tables_init_sql="CP_tables.init.sql"
  mysql -uroot -ppassword -ve "DROP DATABASE IF EXISTS cellpedia; CREATE DATABASE cellpedia"
  mysql -uroot -ppassword -ve "CREATE USER 'cellpedia_user'@'localhost' IDENTIFIED BY 'password'"
  mysql -uroot -ppassword -ve "GRANT ALL PRIVILEGES ON cellpedia.* TO 'cellpedia_user'@'localhost' IDENTIFIED BY 'password'"
  mysql -uroot -ppassword -ve "FLUSH PRIVILEGES"
  mysql -ucellpedia_user -ppassword cellpedia <CP_tables.init.sql
  #The LOCAL keyword is important to avoid access denied issue for loading.
  mysql -ucellpedia_user -ppassword cellpedia -ve "
    LOAD DATA LOCAL INFILE 'cellpedia/CP_anatomy.csv'
		INTO TABLE CP_anatomy 
    FIELDS TERMINATED BY ',' 
    LINES TERMINATED BY '\n'
    IGNORE 1 ROWS;"
  mysql -ucellpedia_user -ppassword cellpedia -ve "
    LOAD DATA LOCAL INFILE 'cellpedia/CP_celltype.csv'
		INTO TABLE CP_celltype 
    FIELDS TERMINATED BY ',' 
    LINES TERMINATED BY '\n'
    IGNORE 1 ROWS;"
  mysql -ucellpedia_user -ppassword cellpedia -ve "
    LOAD DATA LOCAL INFILE 'cellpedia/CP_cell.csv'
		INTO TABLE CP_cell
    FIELDS TERMINATED BY ',' 
    LINES TERMINATED BY '\n'
    IGNORE 1 ROWS;"
fi
###
