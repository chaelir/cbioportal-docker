#!/bin/bash
set -x
stage=$1

if [ $stage == "get_cp" ]; then 
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
    cellpedia.anatomy.xlsx cellpedia.anatomy.csv
  ssconvert -T Gnumeric_stf:stf_assistant \
    -O 'separator=, format=raw quoting-mode=never' \
    cellpedia.celltype.xlsx cellpedia.celltype.csv
  #ssconvert failed to perserve ID numbers as string
  cp cellpedia.differentiated.html cellpedia.differentiated.xls
  ssconvert -T Gnumeric_stf:stf_assistant \
    -O 'separator=; format=raw quoting-mode=never' \
    cellpedia.differentiated.xls cellpedia.differentiated.txt #semi colon seperated values
  sed 's/,/ /g' cellpedia.differentiated.txt | sed 's/;/,/g' >cellpedia.differentiated.csv 
  #MANUAL: load cellpedia.differentiated.csv in MS excel, correct the header rows and anatomy id and save it
fi

#for now, need to manually operate in navicat to prepare the tables and dump 

if [ $stage == "prep_cp" ]; then 
  mysql_root_password="password"
  mysql -uroot -p${mysql_root_password} -ve "DROP DATABASE IF EXISTS cellpedia; CREATE DATABASE cellpedia"
  mysql -uroot -p${mysql_root_password} -ve "CREATE USER 'cellpedia_user'@'localhost' IDENTIFIED BY 'password'"
  mysql -uroot -p${mysql_root_password} -ve "GRANT ALL PRIVILEGES ON cellpedia.* TO 'cellpedia_user'@'localhost' IDENTIFIED BY 'password'"
  mysql -uroot -p${mysql_root_password} -ve "FLUSH PRIVILEGES"
  #MANUAL: load cellpedia.*.csv to navicat, set primariy keys, foreign keys and export as CP_tables.dump.sql
fi
