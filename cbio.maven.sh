#!/bin/bash

# perform maven build of cbio portal

# cbio.maven.sh goal module sub-goal
# e.g. 
# cbio.maven.sh prep_db
# cbio.maven.sh python-validator
# cbio.maven.sh prep_dep security
# cbio.maven.sh prep_dep security
# cbio.maven.sh test core
# cbio.maven.sh install core install-file

# never run, for copy and paste only
# install individual dependency if overall test breaks for the target org.mskcc.cbio:core
# to continue debug light-weightly, do individual test:
if [[ "1" == "2" ]]; then
  mvn test \ 
      -Dtest=TestDaoTextCache \          
      -Ddb.user=cbio_user \
      -Ddb.password=somepassword \
      -rf :core
      -X
fi

set -x

if [[ $1 == "prep_db" ]]; then
  mysql --user root --password=password -ve "DROP DATABASE IF EXISTS cgds_test; CREATE DATABASE cgds_test"
  mysql --user root --password=password -ve "DROP USER IF EXISTS 'cbio_user'@'localhost'; CREATE USER 'cbio_user'@'localhost' IDENTIFIED BY 'somepassword'"
  mysql --user root --password=password -ve "GRANT ALL ON cgds_test.* TO 'cbio_user'@'localhost'"
  mysql --user root --password=password -ve "flush privileges"
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
  PROFILE="charlie"

  if [[ -z $3 ]]; then GOAL="$1"; else GOAL="$1:$3"; fi
  if [[ $2 == "master" ]]; then MODULE=""; else MODULE=":$2"; pushd $2; fi
  mvn -e \
      -P${PROFILE} \
      -Dfinal.war.name=cbioportal \
      -Ddb.user=cbio_user \
      -Ddb.password=somepassword \
      $GOAL $MODULE
  if [[ $2 != "master" ]]; then popd; fi
   
  popd
fi
