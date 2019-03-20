#!/bin/bash
# turn on echoing of each ran command
set -x
stage=$1
if [ -z $stage ]; then echo "input a stage: run_mysql, pop_mysql, build_cbio, or run_cbio"; exit; fi

### define the portal.properties file to be configured by this init script ###
# for Bash compatibility, use "${var}" instead of '$var' or '${var}'
# must use absolute path here to be mounted by docker
build_root="$HOME/setup/cbioportal-docker"
portal_configure_template="$HOME/setup/cbioportal-docker/portal.properties"
portal_configure_file="$HOME/setup/cbioportal-docker/portal.properties.cbioportal1"
docker_template="$HOME/setup/cbioportal-docker/Dockerfile"
docker_cbio_dockerfile="$HOME/setup/cbioportal-docker/Dockerfile.v1.17"
biosql_init_sql="$HOME/setup/cbioportal-docker/db_BS/BS_tables.init.sql"
cellpedia_init_sql="$HOME/setup/cbioportal-docker/db_CP/CP_tables.init.sql"
cellpedia_tables=('CP_anatomy' 'CP_celltype' 'CP_cell')
cell_init_sql="$HOME/setup/cbioportal-docker/db_IM/IM_cell.init.sql"
microbe_init_sql="$HOME/setup/cbioportal-docker/db_IM/IM_microbe.init.sql"
cp -f ${portal_configure_template} ${portal_configure_file}
cp -f ${docker_template} ${docker_cbio_dockerfile}

### current configurable portal.properties variables ###
# for Bash compatibility, changed variable names x.y to x_y
db_user="cbio1"
db_password="P@ssword1"
db_host="cbioDB1"
db_connection_string="jdbc:mysql:\/\/${db_host}\/"
db_portal_db_name="cbioportal1"
sed -i -e "s/db.user=.*/db.user=${db_user}/g" ${portal_configure_file}
sed -i -e "s/db.password=.*/db.password=${db_password}/g" ${portal_configure_file}
sed -i -e "s/db.host=.*/db.host=${db_host}/g" ${portal_configure_file}
sed -i -e "s/db.connection_string=.*/db.connection_string=${db_connection_string}/g" ${portal_configure_file}
sed -i -e "s/db.portal_db_name=.*/db.portal_db_name=${db_portal_db_name}/g" ${portal_configure_file}
#check if changes intended:
#  diff portal.properties portal.properties.cbioportal1

### current configurable none portal.properties variables ###
docker_timezone="America/Los_Angeles"
docker_restart="always"
docker_network="cbio-net1"
docker_cbio_source="."            
#local git source folder of cbioportal-docker
#cbioportal_source="-b v1.17.1+backport4787-4917-5057 https://github.com/thehyve/cbioportal.git cbioportal"
cbioportal_source=""
#local git source folder of cbioportal, at v1.17.1 
docker_cbio_image="cbioportal-v1.17.hack"
docker_cbio_instance="cbioPortal1"
docker_cbio_port=8882
docker_mysql_port=3337
docker_cbio_opt="'-Xms2g -Xmx4g'" #tricky quote issue, important to preserve quote this way
docker_db_wait=10
db_dataseed_path="${HOME}/setup/datahub/seedDB"
db_dataseed_sql="seed-cbioportal_hg19_v2.6.0.sql.gz" 
#how to choose seedDB? see: https://github.com/cBioPortal/datahub/tree/master/seedDB
db_runtime_path="${HOME}/setup/cbioportal-docker-runtime"
db_datahub_path="$HOME/setup/datahub"
db_datahub_priv_path="$HOME/setup/datahub_priv"
db_public_studies=('coadread_tcga')
db_private_studies=()

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
    -e MYSQL_ROOT_PASSWORD="${db_password}" \
    -e MYSQL_USER="${db_user}" \
    -e MYSQL_PASSWORD="${db_password}" \
    -e MYSQL_DATABASE="${db_portal_db_name}" \
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

### pos mysql docker ###
if [ $stage == 'pop_mysql' ]; then
  sleep ${docker_db_wait} ## wait the db to initialize
  docker run \
    --net=${docker_network} \
    -e TZ="${docker_timezone}" \
    -e MYSQL_USER=${db_user} \
    -e MYSQL_PASSWORD=${db_password} \
    -v ${db_dataseed_path}/cgds.sql:/mnt/cgds.sql:ro \
    -v ${db_dataseed_path}/${db_dataseed_sql}:/mnt/seed.sql.gz:ro \
    mysql:5.7 \
    sh -c "cat /mnt/cgds.sql | mysql -h${db_host} -u${db_user} -p${db_password} ${db_portal_db_name} \
      && zcat /mnt/seed.sql.gz |  mysql -h${db_host} -u${db_user} -p${db_password} ${db_portal_db_name}"
fi
# docker exec -it cbioDB1 /bin/bash -c "mysql -hcbioDB1 -ucbio1 -pP@ssword1 cbioportal1"
# docker logs cbioDB1

### build cbioportal docker image
if [ $stage == 'build_cbio' ]; then
  # adding --no-cache if you have't build for a long time to avoid cannot fetch errors from apt-get
  if [[ ! -z ${cbioportal_source} ]]; then git clone ${cbioportal_source}; fi
	#docker build --no-cache -t ${docker_cbio_image} -f ${docker_cbio_dockerfile} ${docker_cbio_source}
  #you will need --no-cache if you haven't build a thing for a while to avoid apt source not found errors...
	docker build -t ${docker_cbio_image} -f ${docker_cbio_dockerfile} ${docker_cbio_source}
  exit
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

### migrate db (optional) ###
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
      -s /mnt/datahub/public/${study} -o"
  done
  for study in ${db_private_studies[@]}; do
    docker exec -it ${docker_cbio_instance} bash -c \
      "metaImport.py -u http://localhost:8080/cbioportal \
      -s /mnt/datahub_priv/${study} -o"
  done
fi

### prepare BS database ###
if [ $stage == 'prep_biosql' ]; then
  ./biosql.init.sh ${biosql_init_sql}
fi
# fully automatic

### load BS database ###
if [ $stage == 'load_BS' ]; then
  docker run \
    --net=${docker_network} \
    -e TZ="${docker_timezone}" \
    -e MYSQL_USER=${db_user} \
    -e MYSQL_PASSWORD=${db_password} \
    -v ${biosql_init_sql}:/mnt/biosql.init.sql:ro \
    mysql:5.7 \
    sh -c "cat /mnt/biosql.init.sql | mysql -h${db_host} -u${db_user} -p${db_password} ${db_portal_db_name}"
fi

### prepare CP database ###
if [ $stage == 'prep_CP' ]; then
  echo '...' 
  #./cellpedia.init.sh ${cellpedia_init_sql} #not needed now, deprecated
  # TODO: fullly automize this step
fi

### load CP database ###
if [ $stage == 'load_CP' ]; then
  echo '...' 
  docker run \
    --net=${docker_network} \
    -e TZ="${docker_timezone}" \
    -e MYSQL_USER=${db_user} \
    -e MYSQL_PASSWORD=${db_password} \
    -v ${cellpedia_init_sql}:/mnt/cellpedia.init.sql:ro \
    mysql:5.7 \
    sh -c "cat /mnt/cellpedia.init.sql | mysql -h${db_host} -u${db_user} -p${db_password} ${db_portal_db_name}"
  for tab in ${cellpedia_tables[@]}; do
    docker run \
    --net=${docker_network} \
    -e TZ="${docker_timezone}" \
    -e MYSQL_USER=${db_user} \
    -e MYSQL_PASSWORD=${db_password} \
    -v ${build_root}/cellpedia/${tab}.csv:/mnt/cellpedia.table.csv:ro \
    mysql:5.7 \
    sh -c "mysql -h${db_host} -u${db_user} -p${db_password} ${db_portal_db_name} -ve \"
    	LOAD DATA LOCAL INFILE '/mnt/cellpedia.table.csv'
    	INTO TABLE ${tab}
    	FIELDS TERMINATED BY ','
    	LINES TERMINATED BY '\n'
    	IGNORE 1 ROWS;\" "
  done
fi

### load IM_cell database
if [ $stage == 'load_IM_cell' ]; then
  echo '...' 
  docker run \
    --net=${docker_network} \
    -e TZ="${docker_timezone}" \
    -v ${cell_init_sql}:/mnt/cell.init.sql:ro \
    mysql:5.7 \
    sh -c "cat /mnt/cell.init.sql | mysql -h${db_host} -u${db_user} -p${db_password} ${db_portal_db_name}"
fi

### load MI database
if [ $stage == 'load_IM_microbe' ]; then
  echo '...' 
  docker run \
    --net=${docker_network} \
    -e TZ="${docker_timezone}" \
    -e MYSQL_USER=${db_user} \
    -e MYSQL_PASSWORD=${db_password} \
    -v ${microbe_init_sql}:/mnt/.init.sql:ro \
    mysql:5.7 \
    sh -c "cat /mnt/microbe.init.sql | mysql -h${db_host} -u${db_user} -p${db_password} ${db_portal_db_name}"
fi