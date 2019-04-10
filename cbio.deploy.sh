#!/bin/bash
# turn on echoing of each ran command
# assumed within the same directory and associated files like:
# portal.properties and Dockerfile
# for Bash compatibility, use "${var}" instead of '$var' or '${var}'

if [ -z $2 ]; then 
  echo "input a stage: \${stage}=dry | run_mysql | prep_mysql | build_cbio | run_cbio | load_cbio"
  echo "and a tag; e.g. \${tag}=v1.17h" 
  echo "  ./cbio.deploy.sh build_cbio v1.17h"
  echo "in the case a tag is provided"
  echo "patches of '\${tag}.patch' will be applied to, such that:"
  echo "  Dockerfile -> Dockerfile.\${tag}.deploy" 
  echo "  portal.properties -> portal.properties.\${tag}.deploy" 
  echo "patches were generated by"
  echo "  diff Dockerfile Dockerfile.\${tag}.edit >Dockerfile.\${tag}.patch"
  echo "  diff Dockerfile Dockerfile.\${tag}.edit >Dockerfile.\${tag}.patch"
  exit
fi

set -x
stage=$1
tag=$2

### pathes must use absolute path here to be mounted by docker
build_root=$(pwd)
build_parent=$(cd .. && pwd)
docker_cbio_dockerfile="${build_root}/Dockerfile"
portal_configure_file="${build_root}/portal.properties"
if [ ! -z ${tag} ]; then
  #apply patches
  patch -o Dockerfile.${tag} Dockerfile Dockerfile.${tag}.patch
  patch -o portal.properties.${tag} portal.properties portal.properties.${tag}.patch
  docker_cbio_dockerfile="${build_root}/Dockerfile.${tag}"
  portal_configure_file="${build_root}/portal.properties.${tag}"
fi

### define the portal.properties file to be configured by this init script ###
immube_init_sql="${build_root}/db_IM/cgds_im.sql"
# this file must be synced between portal and db
cgds_init_sql="${build_root}/cbioportal/db-scripts/src/main/resources/cgds.sql"
mysql_clean_sql="${build_root}/db_IM/cgds_clean.sql"
#NOTE: all IM db scripts were merged into cgds_im.sql
#biosql_init_sql="${build_root}/db_BS/BS_tables.init.sql"
#cellpedia_init_sql="${build_root}/db_CP/CP_tables.init.sql"
#cellpedia_tables=('CP_anatomy' 'CP_celltype' 'CP_cell')
#cell_init_sql="${build_root}/db_IM/IM_cell.init.sql"
#microbe_init_sql="${build_root}/db_IM/IM_microbe.init.sql"

### current configurable none portal.properties variables ###
### all these will go some properties file, say immube.properties later
docker_timezone="America/Los_Angeles"
docker_restart="always"
docker_network="cbio-net1"
#this points to local git source folder of cbioportal-docker
docker_cbio_source="."            
#this points to the local path of cbio source code
git_cbio_local="cbioportal"
git_cbio_remote="https://github.com/chaelir/cbioportal.git"
#local git source folder of cbioportal
docker_cbio_image="cbioportal-${tag}"
docker_cbio_instance="cbioPortal1"
docker_cbio_port=8882
docker_mysql_port=3337
docker_cbio_opt="'-Xms2g -Xmx4g'" #tricky quote issue, important to preserve quote this way
docker_db_wait=10
#how to choose seedDB? see: https://github.com/cBioPortal/datahub/tree/master/seedDB
db_dataseed_path="${build_parent}/datahub/seedDB"
#this is linked to the cgds.sql version of the portal
db_dataseed_sql="seed-cbioportal_hg19_v2.7.2.sql.gz" 
db_runtime_path="${build_parent}/cbioportal-docker-runtime"
db_datahub_path="${build_parent}/datahub"
db_datahub_priv_path="${build_parent}/datahub_priv"
#db_public_studies=('public/coadread_tcga')
db_public_studies=('')
#db_private_studies=('custom/crc_tcga')
db_private_studies=('imh/crc_imh')

### read additional variables from teh property file

set +x
echo "loading ${portal_configure_file}"
if [ -f "${portal_configure_file}" ]; then
  while IFS='=' read -r key value
  do
    if [[ ! -z $(echo ${key} | grep '#') || -z ${key} ]]; then
      continue
    fi
    key=$(echo ${key} | tr '.' '_')
    #echo ${key}="${value}"
    eval ${key}="${value}"
  done < "${portal_configure_file}" 2>/dev/null
  #echo "ignore these errors arising from: ${portal_configure_file}"
  #echo "check important variables loaded from ${portal_configure_file}"
  echo "db_user=${db_user}"
  echo "db_password=${db_password}"
  echo "db_host=${db_host}"
  echo "db_portal_db_name=${db_portal_db_name}"
fi
set -x

### quit to show parameters only ###
if [ $stage == "dry" ]; then exit; fi

### create docker network ###
# create a network if not existing, other do not panic
docker network create ${docker_network} || true

### run mysql docker ###
if [ $stage == 'run_mysql' ]; then
  mkdir ${db_runtime_path}/${db_host} || true
  docker rm -f ${db_host} || true
  docker run -d --restart=${docker_restart} \
    --name=${db_host} \
    --net=${docker_network} \
    -e TZ="${docker_timezone}" \
    -v ${db_runtime_path}/${db_host}:/var/lib/mysql/ \
    -v ${db_datahub_path}/:/mnt/datahub/ \
    -v ${db_datahub_priv_path}/:/mnt/datahub_priv/ \
    -p ${docker_mysql_port}:3306 \
    mysql:5.7
  ### run mysql with seed database ###
  echo "Take Note: access the mysql db with the following command:"
  echo "docker exec -it ${db_host} /bin/bash -c \"mysql -h${db_host} -u${db_user} -p${db_password} ${db_portal_db_name}\""
fi
# docker logs cbioDB1
# these options were obsolete
#    -e MYSQL_ROOT_PASSWORD="${db_password}" \
#    -e MYSQL_USER="${db_user}" \
#    -e MYSQL_PASSWORD="${db_password}" \
#    -e MYSQL_DATABASE="${db_portal_db_name}" \

### prep mysql and cbio dbs ###
if [ $stage == 'prep_mysql' ]; then
  sleep ${docker_db_wait} ## wait the db to initialize
  # docker run \
  #  --net=${docker_network} \
  #  -e TZ="${docker_timezone}" \
  #  -v ${mysql_clean_sql}:/mnt/cgds_clean.sql:ro \
  #  mysql:5.7 \
  #  sh -c "cat /mnt/cgds_clean.sql | mysql -h${db_host} -u${db_user} -p${db_password} ${db_portal_db_name}"    
  docker run \
    --net=${docker_network} \
    -e TZ="${docker_timezone}" \
    -v ${cgds_init_sql}:/mnt/cgds.sql:ro \
    mysql:5.7 \
    sh -c "cat /mnt/cgds.sql | mysql -h${db_host} -u${db_user} -p${db_password} ${db_portal_db_name}"
  docker run \
    --net=${docker_network} \
    -e TZ="${docker_timezone}" \
    -v ${db_dataseed_path}/${db_dataseed_sql}:/mnt/seed.sql.gz:ro \
    mysql:5.7 \
    sh -c "zcat /mnt/seed.sql.gz |  mysql -h${db_host} -u${db_user} -p${db_password} ${db_portal_db_name}"
fi
# docker exec -it cbioDB1 /bin/bash -c "mysql -hcbioDB1 -ucbio1 -pP@ssword1 cbioportal1"
# docker logs cbioDB1
# these options were obsolete
#    -e MYSQL_USER=${db_user} \
#    -e MYSQL_PASSWORD=${db_password} \

### prep immube database ###
if [ $stage == 'prep_mysql_im' ]; then
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
fi

### build cbioportal docker image
if [ $stage == 'build_cbio' ]; then
  if [[ ! -d ${git_cbio_local} ]]; then 
    git clone ${git_cbio_remote} #if no local source, clone it entirely
  fi
  pushd ${git_cbio_local} 
  git pull origin ${tag} #if existing, checkout the branch (keep it the same tag)
  git checkout ${tag}  #update the branch
  popd
	docker build -t ${docker_cbio_image} -f ${docker_cbio_dockerfile} ${docker_cbio_source}
	#docker build --no-cache -t ${docker_cbio_image} -f ${docker_cbio_dockerfile} ${docker_cbio_source}
  #you will need --no-cache if you haven't build a thing for a while to avoid apt source not found errors...
  exit
fi

### rerun cbio portal service with changes saved to image ###
if [ $stage == 'rerun_cbio' ]; then
  docker stop ${docker_cbio_instance}
  docker commit ${docker_cbio_instance} ${docker_cbio_image}
  docker rm -f ${docker_cbio_instance}
  docker run -d --restart=${docker_restart} \
    --name=${docker_cbio_instance} \
    --net=${docker_network} \
    -e TZ="${docker_timezone}" \
    -e CATALINA_OPTS='${docker_cbio_opt}' \
    -v ${db_datahub_path}/:/mnt/datahub/ \
    -v ${db_datahub_priv_path}/:/mnt/datahub_priv/ \
    -p ${docker_cbio_port}:8080 \
		${docker_cbio_image}
  # property file must be hard copied to container
  docker cp ${portal_configure_file} ${docker_cbio_instance}:/cbioportal/portal.properties
fi

### run cbio portal service ###
if [ $stage == 'run_cbio' ]; then
  docker rm -f ${docker_cbio_instance} || true
  docker run -d --restart=${docker_restart} \
    --name=${docker_cbio_instance} \
    --net=${docker_network} \
    -e TZ="${docker_timezone}" \
    -e CATALINA_OPTS='${docker_cbio_opt}' \
    -v ${db_datahub_path}/:/mnt/datahub/ \
    -v ${db_datahub_priv_path}/:/mnt/datahub_priv/ \
    -p ${docker_cbio_port}:8080 \
		${docker_cbio_image}
  # property file must be hard copied to container
  docker cp ${portal_configure_file} ${docker_cbio_instance}:/cbioportal/portal.properties
fi
# docker exec -it cbioPortal1 /bin/bash ""
# docker logs cbioPortal1

### migrate db ###
if [ $stage == 'migr_cbio' ]; then
  docker exec -it ${docker_cbio_instance} bash -c \
    "migrate_db.py --properties-file /cbioportal/portal.properties \
    --sql /cbioportal/db-scripts/src/main/resources/migration.sql"
fi

### load cbio database ###
if [ $stage == 'load_cbio' ]; then
  for study in ${db_public_studies[@]}; do
    docker exec -it ${docker_cbio_instance} bash -c \
      "metaImport.py -u http://localhost:8080/cbioportal \
      -s /mnt/datahub/${study} -o"
  done
  for study in ${db_private_studies[@]}; do
    docker exec -it ${docker_cbio_instance} bash -c \
      "metaImport.py -u http://localhost:8080/cbioportal \
      -s /mnt/datahub_priv/${study} -o"
  done
fi

### get an interactive mysql
# docker exec -it cbioDB1 sh -c "mysql -ucbio1 -pP@ssword1 cbioportal1" 
