#!/bin/bash

# perform maven build of cbio portal

# cbio.maven.sh goal module opt
# e.g. 
# cbio.maven.sh prep_db
# cbio.maven.sh python-validator
# cbio.maven.sh prep_dep security
# cbio.maven.sh prep_dep security
# cbio.maven.sh test master
# cbio.maven.sh integration-test master
# cbio.devel.sh compile master
# seems building child pom directly cause resources not properlly set
# cbio.maven.sh test persistence-mybatis
# cbio.maven.sh test core -Dtest=TestDaoTextCache

# never run, for copy and paste purpose only
# install individual dependency if overall test breaks for the target org.mskcc.cbio:core
# to continue debug light-weightly, do individual test:
if [[ "1" == "2" ]]; then
  mvn test \ 
      -Dtest=TestDaoTextCache \          
      -Ddb.user=cbio_user \
      -Ddb.password=somepassword \
      -rf :core
fi

set -x

if [[ $1 == "prep_cgds" ]]; then
  #cgds will often be cleaned while cbioportal is relatively stable
  mysql --user root --password=password -ve "DROP DATABASE IF EXISTS cgds_test; CREATE DATABASE cgds_test"
  mysql --user root --password=password -ve "DROP USER IF EXISTS 'cbio_user'@'localhost'; CREATE USER 'cbio_user'@'localhost' IDENTIFIED BY 'somepassword'"
  mysql --user root --password=password -ve "GRANT ALL ON cgds_test.* TO 'cbio_user'@'localhost'"
  mysql --user root --password=password -ve "GRANT ALL ON cbioportal.* TO 'cbio_user'@'localhost'"
  mysql --user root --password=password -ve "flush privileges"
if [[ $1 == "prep_tomcat" ]]; then
  mysql --user root --password=password -ve "CREATE DATABASE cbioportal"
  mysql --user root --password=password -ve "CREATE USER 'cbio_user'@'localhost' IDENTIFIED BY 'somepassword'"
  mysql --user root --password=password -ve "GRANT ALL ON cbioportal.* TO 'cbio_user'@'localhost'"
  mysql --user root --password=password -ve "flush privileges"
  mysql --user=cbio_user --password=somepassword cbioportal < ${PORTAL_HOME}/db-scripts/src/main/resources/cgds.sql
  mysql --user=cbio_user --password=somepassword cbioportal < ${PORTAL_HOME}/db-scripts/src/main/resources/cgds_im.sql
elif [[ $1 == "prep_dep" ]]; then
  #deps = ('business',  'db-scripts', 'service')  
  dep=$2
  pushd cbioportal
  if [[ ${dep} == "security-spring" ]]; then
    mvn install:install-file -Dfile=security/${dep}/target/${dep}-1.17.1.jar -DpomFile=security/${dep}/pom.xml
  else
    mvn install:install-file -Dfile=${dep}/target/${dep}-1.17.1.jar -DpomFile=${dep}/pom.xml
  fi
  popd
elif [[ $1 == "python-validator" ]]; then
  # vailidate python scripts first
  sudo brew install python3.4-venv
  python3.4 -m venv python-env-validator
  source python-env-validator/bin/activate
  trap 'deactivate' EXIT
  pip install -r requirements.txt
  export PYTHONPATH="$PWD/core/src/main/scripts:$PYTHONPATH"
  pushd core/src/test/scripts/
  python unit_tests_validate_data.py
  python system_tests_validate_data.py
  python system_tests_validate_studies.py
  popd
elif [[ $1 == "sanity-checks" ]]; then
  pushd cbioportal
  bash test/test_db_version.sh
  popd
elif [[ $1 == "end-to-end" ]]; then
  pushd cbioportal
  mkdir -p .m2
  cp .travis/settings.xml .m2
  mvn -e \
     -Ppublic -DskipTests \
     -Dfinal.war.name=cbioportal \
     clean install
  popd
else
  #proceed with a actual maven goal for java testing
  pushd cbioportal
  mkdir -p .m2
  cp .travis/settings.xml .m2
  PROFILE=""
  GOAL=$1
  OPT=$3

  if [[ $2 == "master" ]]; then 
    MODULE=""
    PROFILE="-Pcharlie"
  elif [[ -z $(echo $MODULE | grep '-') ]]; then
    pushd $2 #things like core 
  elif [[ $2 == "db-scripts" ]]; then 
    pushd $2 #things like db-scripts
  else 
    SUBDIR=$(echo $2 | cut -d '-' -f 1)
    pushd $SUBDIR/$2
  fi

  ls pom.xml
  mvn -e ${PROFILE} -f pom.xml \
      -Dfinal.war.name=cbioportal \
      -Ddb.user=cbio_user \
      -Ddb.password=somepassword \
      ${OPT} \
      ${GOAL}

  if [[ $2 != "master" ]]; then 
      popd
      continue
  fi
   
  popd
fi
