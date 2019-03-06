#rename and export biosql tables with one script
#require perl, mysql, mysqladmin, mysqldump, git 
#biosql_user of mysql is temporary
#===========================================

set -x
if [ -z $1 ]; then biosql_dump_sql="BS_tables_export.sql"; else biosql_dump_sql=$1; fi;
biosql_source="https://github.com/chaelir/biosql.git"
mysql_root_password="password"

#Clone biosql and apply patches
#==========================================
#TODO: use recursive diff and patch
#[mac] brew install openssl mysql-connector-c
cpan install DBD::mysql
git clone ${biosql_source} || true
cd biosql/scripts #change to scripts
patch load_ncbi_taxonomy.pl load_ncbi_taxonomy.pl.patch
cd ..

#Creat biosql in mysql
#===========================================
mysql -uroot -p${mysql_root_password} -ve "DROP biosql; CREATE DATABASE biosql"
mysql -uroot -p${mysql_root_password} -ve "CREATE USER 'biosql_user'@'localhost' IDENTIFIED BY 'password'"
mysql -uroot -p${mysql_root_password} -ve "GRANT ALL PRIVILEGES ON biosql.* TO 'biosql_user'@'localhost' IDENTIFIED BY 'password'"
mysql -uroot -p${mysql_root_password} -ve "FLUSH PRIVILEGES"
mysql -ubiosql_user -ppassword biosql < sql/biosqldb-mysql.sql

#Populate biosql with NCBI taxonomy
#===========================================
scripts/load_ncbi_taxonomy.pl --download --driver mysql --dbname biosql --dbuser biosql_user --dbpass password

#Rename tables in biosql.* by biosql.BS_*
#===========================================
mysql -ubiosql_user -ppassword -AN -e"select concat('alter table ', db, '.', tb, ' rename ', db, '.', prfx, tb,';') from (select table_schema db,table_name tb from information_schema.tables where table_schema='biosql') A,(SELECT 'BS_' prfx) B" | mysql -ubiosql_user -ppassword -AN

#Export BS_* to an importable file
#===========================================
cd .. #change to root working dir
mysqldump -ubiosql_user -ppassword biosql > ${biosql_dump_sql}

#Clean up biosql_user and biosql db
#===========================================
mysql -uroot -p${mysql_root_password} -ve "DROP USER 'biosql_user'@'localhost';"
mysql -uroot -p${mysql_root_password} -ve "DROP DATABASE biosql;"
