#!/bin/bash
# turn on echoing of each ran command
set -x

### define the portal.properties file to be configured by this init script ###
# for Bash compatibility, use "${var}" instead of '$var' or '${var}'
portal_configure_file="${HOME}/setup/cbioportal-docker/portal.properties.cbioportal1"

### current configurable portal.properties variables ###
# for Bash compatibility, changed variable names x.y to x_y
db_user="cbio1"
db_password="P@ssword1"
db_host="cbioDB1"
portal_db_name="cbioportal1"
sed -i -e "s/db.user=.*/db.user=${db_user}/g" ${portal_configure_file}
sed -i -e "s/db.password=.*/db.password=${db_password}/g" ${portal_configure_file}
sed -i -e "s/db.host=.*/db.host=${db_host}/g" ${portal_configure_file}
sed -i -e "s/portal.db.name=.*/portal.db.name=${portal_db_name}/g" ${portal_configure_file}

### current configurable none portal.properties variables ###
docker_network="cbio-net1"
docker_cbio_source="https://github.com/chaelir/cbioportal-docker.git"
docker_cbio_image="cbioportal-v1.17"
docker_cbio_instance="cbioPortal1"
docker_cbio_dockerfile="Dockerfile.v1.17"
docker_cbio_port=8881
docker_cbio_opt="\'-Xms2g -Xmx4g\'" #important to keep single quote
docker_db_wait=10
db_dataseed_path="${HOME}/setup/datahub/seedDB"
db_dataseed_sql="seed-cbioportal_hg19_v2.6.0.sql.gz"
db_runtime_path="${HOME}/setup/cbioportal-docker-runtime"

### create docker network ###
# create a network if not existing, other do not panic
docker network create ${docker_network} || true

### run mysql docker ###
mkdir ${db_runtime_path}/${db_host} || true
docker rm -f ${db_host} || true
docker run -d --restart=always \
  --name=${db_host} \
  --net=${docker_network} \
  -e MYSQL_ROOT_PASSWORD="${db_password}" \
  -e MYSQL_USER=${db_user} \
  -e MYSQL_PASSWORD="${db_password}" \
  -e MYSQL_DATABASE=${portal_db_name} \
  -v ${db_runtime_path}/${db_host}:/var/lib/mysql/ \
  mysql:5.7

### run mysql with seed database ###
sleep ${docker_db_wait} ## wait the db to initialize
docker run \
  --net=${docker_network} \
  -e MYSQL_USER=${db_user} \
  -e MYSQL_PASSWORD=${db_password} \
  -v ${db_dataseed_path}/cgds.sql:/mnt/cgds.sql:ro \
  -v ${db_dataseed_path}/${db_dataseed_sql}:/mnt/seed.sql.gz:ro \
  mysql:5.7 \
  sh -c "cat /mnt/cgds.sql | mysql -h${db_host} -u${db_user} -p${db_password} ${portal_db_name} \
      && zcat /mnt/seed.sql.gz |  mysql -h${db_host} -u${db_user} -p${db_password} ${portal_db_name}"

### build cbioportal docker image
# adding --no-cache is important to avoid cannot fetch errors from apt-get
docker build --no-cache -t ${docker_cbio_image} -f ${docker_cbio_dockerfile} ${docker_cbio_source}

### migrate db (optional) ###
#docker run --rm -it --net cbio-net \
#    -v /<path_to_config_file>/portal.properties:/cbioportal/portal.properties:ro \
#    cbioportal-image \
#    migrate_db.py -p /cbioportal/portal.properties -s /cbioportal/db-scripts/src/main/resources/migration.sql

### run cbio portal service ###
docker run -d --restart=always \
    --name=${docker_cbio_instance} \
    --net=${docker_network} \
    -v ${portal_configure_file}:/cbioportal/portal.properties:ro \
    -e CATALINA_OPTS=${docker_cbio_opt}  \
    -p ${docker_cbio_port}:8080 \
		${docker_cbio_image}

