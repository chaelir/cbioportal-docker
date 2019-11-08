#!/bin/bash
# turn on echoing of each ran command
# assumed within the same directory and associated files like:
# portal.properties and Dockerfile
# for Bash compatibility, use "${var}" instead of '$var' or '${var}'

#SECTION: input parameters
if [ -z $2 ]; then 
  echo "###input a stage and a cbio branch name:"
  echo "#  available stages: \${stage}=dry | get_network | run_mysql | seed_mysql | build_cbio and more, see below"
  echo "#  available branches: \${branch}=release-3.0.0"
  echo "### Here a new workflow based on https://github.com/cBioPortal/cbioportal/tree/master/docs/docker"
  echo "#  [get_network]: cbio.deploy.sh get_network \${branch} -> cbio-net running"
  echo "#  [run_mysql]: cbio.deploy.sh run_mysql \${branch} -> mysql:5.7 running"
  echo "#  [seed_mysql]: cbio.deploy.sh seed_mysql \${branch} -> mysql:5.7 running with seedDB"
  echo "#  [build_cbio]: cbio.deploy.sh build_cbio \${branch} -> cbioportal:\${branch} built"
  echo "#  [migrate_cbio]: cbio.deploy.sh build_cbio \${branch} -> cbioportal:\${branch} db version"
  echo "#  [create_mongo]: cbio.deploy.sh create_mongo \${branch} -> "
  echo "#  [create_session]: cbio.deploy.sh create_session \${branch} -> "
  echo "#  [run_cbio]: cbio.deploy.sh run_cbio \${branch} -> cbioportal:\${branch} running"
  echo "#  [pop_cbio]: cbio.deploy.sh pop_cbio \${branch} -> add data sets to cbioportal:\${branch}"
  echo "#  [restart_cbio]: "
  echo "#"  
  echo "### obsolete stage and its output:"
  echo "#  [seed_mysql_im]: cbio.deploy.sh seed_mysql_im \${branch} -> mysql:5.7 running with seedDB and mimmubeDB"
  echo "### Here we describe, github forks from cBioPortal to chaelir; all branch names are perserved"
  echo "#  cBioPortal/cbioportal -> chaelir/cbioportal "
  echo "#  cBioPortal/datahub -> chaelir/datahub "
  exit
fi

#set -x
stage=$1
branch=$2
portal_public_ip="34.214.235.121"

###SECTION: pathes must use absolute path here to be mounted by docker
build_root=$(pwd)
build_parent=$(cd .. && pwd)

###SECTION: define the mimmube sql files to be mapped by this script
#NOTE: all IM db scripts are now merged into cgds_im.sql
#NOtE: these sql files must be synced between the cbio and the mysql db
immube_init_sql="${build_root}/db_IM/cgds_im.sql"
mysql_clean_sql="${build_root}/db_IM/cgds_clean.sql"

###SECTION: configurable none portal.properties variables ###
#NOTE: all these will go some properties file, say immube.properties later
docker_timezone="America/Los_Angeles"
docker_restart="always"
docker_network="cbio-net1"
#this points to local git source folder of cbioportal-docker
#docker_cbio_source="."          
#this points to the local git source folder of cbioportal
git_cbio_local="cbioportal"
git_cbio_branch=${branch}
#git_cbio_remote="https://github.com/chaelir/cbioportal.git"
git_datahub_remote="https://github.com/chaelir/datahub.git"
git_cbio_remote="https://github.com/dippindots/cbioportal.git"
portal_configure_file="portal.properties"
docker_cbio_dockerfile="docker/web-and-data/Dockerfile"
docker_cbio_image="cbioportal:${git_cbio_branch}"
docker_cbio_instance="cbioPortal1"
docker_cbio_port=8882
docker_mysql_port=3337
#docker_cbio_opt="'-Xms2g -Xmx4g'" #tricky quote issue for direct execution, important to preserve quote this way
docker_cbio_opt="-Xms2g -Xmx4g"
docker_db_wait=10

#seedDB
db_root_password="P@ssword1"
#how to choose seedDB? see: https://github.com/cBioPortal/datahub/tree/master/seedDB
#  make sure the seed version is consistent with portal version before seed_mysql
db_dataseed_path="${build_parent}/datahub/seedDB"
db_dataseed_sql="${db_dataseed_path}/seed-cbioportal_hg19_v2.7.3.sql.gz" 
cgds_init_sql="${db_dataseed_path}/cgds_v2.8.1.sql"
# local folders for mysql files
db_runtime_path="${build_parent}/cbioportal-docker-runtime"
# local folders for public and private data files
db_datahub_path="${build_parent}/datahub"
db_datahub_priv_path="${build_parent}/datahub_priv"
db_public_studies=('')
#db_private_studies=('public/genie')
db_public_studies=('public/coadread_tcga')
#db_public_studies=('public/coadread_tcga public/coadread_dfci_2016 public/coadread_genentech public/coadread_mskcc public/coadread_tcga')
#db_private_studies=('imh/crc_imh')
#use git lfs fetch to fetch all lfs files
#use git lfs checkout to checkout fetched file

###SECTION: read additional variables from teh property file
echo "#loading ${portal_configure_file}"
if [ -f "${portal_configure_file}" ]; then
  #echo "ignore these errors arising from: ${portal_configure_file}"
  #set +x
  while IFS='=' read -r key value
  do
    if [[ ! -z $(echo ${key} | grep '#') || -z ${key} ]]; then
      continue
    fi
    key=$(echo ${key} | tr '.' '_')
    #echo ${key}="${value}"
    eval ${key}="${value}"
  done < "${portal_configure_file}" 2>/dev/null
  #set -x
fi

###SECTION: dry mode: show parameters only ###
if [ $stage == "dry" ]; then
  #echo "check important variables loaded from ${portal_configure_file}"
  echo "#in portal.properties file:"
  echo "  db_user=${db_user}"
  echo "  db_password=${db_password}"
  echo "  db_host=${db_host}"
  echo "  db_portal_db_name=${db_portal_db_name}"
  echo "#out portal.properties file:"
  echo "  docker_network=${docker_network}"
  echo "  docker_cbio_image=${docker_cbio_image}"
  echo "  docker_cbio_instance=${docker_cbio_instance}"
  echo "  docker_cbio_port=${docker_cbio_port}"
  echo "  docker_mysql_port=${docker_mysql_port}"
fi

###SECTION: create docker network ###
# create a network if not existing, other do not panic
if [ $stage == "get_network" ]; then
  cmd="docker network create ${docker_network} || true"
  echo $cmd
fi

###SECTION: run mysql docker ###
if [ $stage == 'run_mysql' ]; then
  cmd="(cd ${build_parent} 
	  && git clone ${git_datahub_remote} || true) \
    && (mkdir -p ${db_runtime_path}/${db_host} || true) \
    && (mkdir -p ${db_datahub_priv_path} || true) \
    && (docker pull mysql:5.7 || true) \
  	&& (docker rm -f ${db_host} || true) \
    && docker run -d --restart=${docker_restart} \
       --name=${db_host} \
       --net=${docker_network} \
       -e TZ="${docker_timezone}" \
       -e MYSQL_ROOT_PASSWORD=${db_root_password} \
  		 -e MYSQL_USER=${db_user} \
  		 -e MYSQL_PASSWORD=${db_password} \
  		 -e MYSQL_DATABASE=${db_portal_db_name} \
       -v ${db_runtime_path}/${db_host}:/var/lib/mysql/ \
       -v ${db_datahub_path}/:/mnt/datahub/ \
       -v ${db_datahub_priv_path}/:/mnt/datahub_priv/ \
       -p ${docker_mysql_port}:3306 \
       mysql:5.7"
  echo $cmd
  ### run mysql with seed database ###
  #echo "Take a note: access the running mysql db and its logs with the following command:"
  echo "#docker exec -it ${db_host} /bin/bash -c \"mysql -h${db_host} -uroot -p${db_root_password}\""
  echo "#docker exec -it ${db_host} /bin/bash -c \"mysql -h${db_host} -u${db_user} -p${db_password} ${db_portal_db_name}\""
  echo "#docker logs ${db_host}"
fi

###SECTION: seed standard cbio db ###
if [ $stage == 'seed_mysql' ]; then
  #sleep ${docker_db_wait} ## wait the db to initialize
  cmd="docker run \
    --net=${docker_network} \
    -e TZ="${docker_timezone}" \
    -v ${cgds_init_sql}:/mnt/cgds.sql:ro \
    mysql:5.7 \
    sh -c \"cat /mnt/cgds.sql | mysql -h${db_host} -u${db_user} -p${db_password} ${db_portal_db_name}\" \
  && docker run \
    --net=${docker_network} \
    -e TZ="${docker_timezone}" \
    -v ${db_dataseed_sql}:/mnt/seed.sql.gz:ro \
    mysql:5.7 \
    sh -c \"zcat /mnt/seed.sql.gz |  mysql -h${db_host} -u${db_user} -p${db_password} ${db_portal_db_name}\" "
  echo $cmd
  echo "#docker exec -it ${db_host} /bin/bash -c \"mysql -h${db_host} -u${db_user} -p${db_password} ${db_portal_db_name}\""
  echo "#docker logs ${db_host}"
fi

###SECTION: seed immube db ###
if [ $stage == 'seed_mysql_im' ]; then
  if [[ -z ${immube_init_sql} ]]; then
    echo "immube database file not found: ${immube_init_sql}" 
    exit
  fi
  docker run \
    --net=${docker_network} \
    -e TZ="${docker_timezone}" \
    -v ${immube_init_sql}:/mnt/immube.init.sql:ro \
    mysql:5.7 \
    sh -c "cat /mnt/immube.init.sql | mysql -h${db_host} -u${db_user} -p${db_password} ${db_portal_db_name}"
  echo "Take a note: access the running mysql db with the following command:"
  echo "docker exec ${db_host} /bin/bash -c \"mysql -h${db_host} -u${db_user} -p${db_password} ${db_portal_db_name}\""
  echo "docker logs ${db_host}"
fi

###SECTION: build cbioportal docker image
if [ $stage == 'build_cbio' ]; then
  cmd="echo had_cloned_cbio"
  if [[ ! -d ${git_cbio_local} ]]; then 
    cmd="git clone ${git_cbio_remote}" #if no local source, clone it entirely
  fi
  #NOTE: you will need --no-cache if you haven't build a thing for a while to avoid apt source not found errors...
  #NOTE: overwrites the portal.properties file as intended
  cmd="$cmd \
    && pushd ${git_cbio_local} \
  	&& git pull origin ${git_cbio_branch} \
  	&& git checkout ${git_cbio_branch} \
	&& docker build --tag ${docker_cbio_image} -f ${docker_cbio_dockerfile} . \
	&& popd"
    #&& cp ../${portal_configure_file} . \
  echo $cmd
  echo "#docker images" #you should see cbioportal:${git_cbio_branch} is available
fi

###SECTION: run cbio portal service ###
if [ $stage == 'run_cbio' ]; then
  # property file must be hard copied to an instance, why?
  cmd="(docker rm -f ${docker_cbio_instance} || true) \
  	&& docker run -d --restart=${docker_restart} \
    	--name=${docker_cbio_instance} \
    	--net=${docker_network} \
        -v ${build_root}/${portal_configure_file}:/cbioportal/portal.properties:ro \
	-e JAVA_OPTS='-Xms2g
                      -Xmx4g
                      -Dauthenticate=noauthsessionservice
                      -Dsession.service.url=http://cbio-session-service:5000/api/sessions/my_portal/
                     ' \
    	-e TZ="${docker_timezone}" \
    	-p ${docker_cbio_port}:8080 \
	${docker_cbio_image} \
	/bin/sh -c 'java \$JAVA_OPTS -jar webapp-runner.jar /cbioportal-webapp'"
  echo $cmd
  echo "#docker exec -it ${docker_cbio_instance} /bin/bash -c \"echo command\" "
  echo "#docker logs ${docker_cbio_instance}"
fi
# docker exec -it cbioPortal1 /bin/bash ""
# docker logs cbioPortal1

###SECTION: rerun cbio portal service with manual changes and property file changes saved
if [ $stage == 'rerun_cbio' ]; then
  # change container context by hard copying property files to container and rerun
  cmd="docker cp ${portal_configure_file} ${docker_cbio_instance}:/cbioportal/portal.properties \
    && docker stop ${docker_cbio_instance} \
  	&& docker commit ${docker_cbio_instance} ${docker_cbio_image} \
  	&& docker rm -f ${docker_cbio_instance} \
  	&& docker run -d --restart=${docker_restart} \
    	 --name=${docker_cbio_instance} \
    	 --net=${docker_network} \
    	 -e TZ="${docker_timezone}" \
    	 -e CATALINA_OPTS='${docker_cbio_opt}' \
    	 -v ${db_datahub_path}/:/mnt/datahub/ \
    	 -v ${db_datahub_priv_path}/:/mnt/datahub_priv/ \
    	 -p ${docker_cbio_port}:8080 \
	 ${docker_cbio_image}"
  echo $cmd
  echo "#docker exec -it ${docker_cbio_instance} /bin/bash -c \"echo command\" "
  echo "#docker logs ${docker_cbio_instance}"
fi

###SECTION: migrate seedDB ###
if [ $stage == 'migrate_cbio' ]; then
  cmd="docker run --net ${docker_network} --rm -it \
      -v ${build_root}/${portal_configure_file}:/cbioportal/portal.properties:ro \
      ${docker_cbio_image} \
      /cbioportal/core/src/main/scripts/migrate_db.py \
      --properties-file /cbioportal/portal.properties \
      --sql /cbioportal/db-scripts/src/main/resources/migration.sql"
  echo $cmd
fi

###SECTION: add mongoDB ###
if [ $stage == 'create_mongo' ]; then
  cmd="docker run -d --net ${docker_network} \
       --name=mongoDB \
       -e MONGO_INITDB_DATABASE=session_service \
       mongo:3.6.6"       
  echo $cmd
fi

###SECTION: add session ###
if [ $stage == 'create_session' ]; then
  cmd="docker run -d --net ${docker_network} \
       --name=cbio-session-service \
       -e JAVA_OPTS='-Dspring.data.mongodb.uri=mongodb://mongoDB:27017/session-service' \
       cbioportal/session-service:latest"
  echo $cmd
fi


###SECTION: load cbio database ###
if [ $stage == 'pop_cbio' ]; then
  cmd="echo add_study_data"
  for study in ${db_public_studies[@]}; do
    cmd="$cmd && docker run --net ${docker_network} --rm -it \
    	  -v ${db_datahub_path}/:/mnt/datahub/ \
	    ${docker_cbio_image} 
          metaImport.py -u http://${portal_public_ip}:8882 \
          -s /mnt/datahub/${study} -o"
  done
          #-v ${build_root}/${portal_configure_file}:/cbioportal/portal.properties:ro \
    	  #-v ${db_datahub_priv_path}/:/mnt/datahub_priv/ \
  #for study in ${db_private_studies[@]}; do
  #  cmd="$cmd && docker exec ${docker_cbio_instance} bash -c \
  #    'metaImport.py -u http://localhost:8080/cbioportal \
  #    -s /mnt/datahub_priv/${study} -o'"
  #done
  echo $cmd
fi
