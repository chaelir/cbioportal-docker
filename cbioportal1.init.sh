#!/bin/bash
# turn on echoing of each ran command
set -x

### define the portal.properties file to be configured by this init script ###
# for Bash compatibility, use "${var}" instead of '$var' or '${var}'
my_configure_file="${HOME}/setup/cbioportal-docker/portal.properties.cbioportal1"

### current configurable portal.properties variables ###
# for Bash compatibility, changed variable names x.y to x_y
db_user='cbio1'
db_password='P@ssword1'
db_host='cbioDB1'
portal_db_name='cbioportal1'
sed -i -e "s/db.user=.*/db.user=${db_user}/g" ${my_configure_file}
sed -i -e "s/db.password=.*/db.password=${db_password}/g" ${my_configure_file}
sed -i -e "s/db.host=.*/db.host=${db_host}/g" ${my_configure_file}
sed -i -e "s/portal.db.name=.*/portal.db.name=${portal_db_name}/g" ${my_configure_file}

### current configurable none portal.properties variables ###
docker_network='cbio-net1'
docker_cbio_source='https://github.com/thehyve/cbioportal-docker.git'
docker_cbio_image='cbioportal-image1'
docker_cbio_instance=
docker_cbio_port=8881

exit

### create docker network ###
docker network create ${docker_network}

### run mysql docker ###
docker run -d --restart=always \
  --name=run-mysql \
  --net=${docker_network} \
  -e MYSQL_ROOT_PASSWORD="${db_password}" \
  -e MYSQL_USER=${db_user} \
  -e MYSQL_PASSWORD="${db_password}" \
  -e MYSQL_DATABASE=${portal_db_name} \
  -v /${db_runtime_path}/${db_host}:/var/lib/mysql/ \
  mysql:5.7

### run mysql with seed database ###
docker run \
  --name=load-seeddb \
  --net=${docker_network} \
  -e MYSQL_USER=${db_user} \
  -e MYSQL_PASSWORD=${db_password} \
  -v ${db_dataseed_path}/cgds.sql:/mnt/cgds.sql:ro \
  -v ${db_dataseed_path}/${db_dataseed_sql}:/mnt/seed.sql.gz:ro \
  mysql:5.7 \
  sh -c "cat /mnt/cgds.sql | mysql -h${db_host} -u'$MYSQL_USER' -p'$MYSQL_PASSWORD' ${portal_db_name} \
      && zcat /mnt/seed.sql.gz |  mysql -h${db_host} -u'$MYSQL_USER' -p'$MYSQL_PASSWORD' ${portal_db_name}"

### build cbioportal docker image
docker build -t ${docker_image} https://github.com/thehyve/cbioportal-docker.git

### migrate db (optional) ###
#docker run --rm -it --net cbio-net \
#    -v /<path_to_config_file>/portal.properties:/cbioportal/portal.properties:ro \
#    cbioportal-image \
#    migrate_db.py -p /cbioportal/portal.properties -s /cbioportal/db-scripts/src/main/resources/migration.sql

### run cbio portal service ###
docker run -d --restart=always \
    --name=run-cbioportal \
    --net=${docker_network} \
    -v /<path_to_config_file>/portal.properties:/cbioportal/portal.properties:ro \
    -e CATALINA_OPTS='-Xms2g -Xmx4g' \
    -p 8081:8080 \
    cbioportal-image


