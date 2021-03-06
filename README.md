# cbioportal-docker @ Chaelir #

## Instructions ##

### For users ###
Identify a cbioportal branch you would like to use, e.g. rc .
Deploy the instances based on this choice.
```
./cbio.deploy.sh get_network rc
./cbio.deploy.sh run_mysql rc
./cbio.deploy.sh prep_mysql rc 
./cbio.deploy.sh seed_mysql rc
./cbio.deploy.sh build_cbio rc
./cbio.deploy.sh run_cbio rc
./cbio.deploy.sh populate_cbio rc

```
Now check your browser at http://localhost:8882/cbioportal/

### For developers ###
1. Start with the code of a working branch at cbioportal, say rc.
Process exactly the same as above.

2. Create a branch name you would like your code be in deploy, e.g. devel
Commit changes you made to the code to the devel branch, which will run cbioportal:rc

3. Debug your changes using local dockerized portal and db
configure local portal configuration in portal.properties
configure local log configuration in log4j.properties
These files will be used at the 'build_cbio' stage to build the portal docker image

```
pushd db_IM
./cgds_im.init.sh
popd db_IM
./cbio.devel.sh prep_db
./cbio.devel.sh clean core
./cbio.devel.sh integration-test core
./cbio.devel.sh integration-test core -Dtest=TestDaoCellProfile
./cbio.deploy.sh build_cbio devel
./cbio.deploy.sh run_mysql devel
./cbio.deploy.sh prep_mysql devel
./cbio.deploy.sh run_cbio devel
./cbio.deploy.sh load_cbio devel
```

When you are done, push your changes to the remote 


### Obsolete instructions (donot follow) ###
(see notes/2018Sep23.cbio.local.rst)
```
### Handling dependencies in Mac OSX
brew install git-lfs
brew install mysql@5.7 #very version picky, has to use mysql57
brew install maven
brew install tomcat@8
brew install mysql-java
pip install mysql-python
mysql_upgrade -u root -p password --force
brew services start tomcat@8
brew services start mysql@5.7
### Handling mysql
# It is important to always grant access to cgds_test.* and cbioportal.* that both test and tomcat will work
mysql --user root --password=password -ve "CREATE DATABASE cbioportal"
mysql --user root --password=password -ve "CREATE USER 'cbio_user'@'localhost' IDENTIFIED BY 'somepassword'"
mysql --user root --password=password -ve "GRANT ALL ON cbioportal.* TO 'cbio_user'@'localhost'"
mysql --user root --password=password -ve "GRANT ALL ON cgds_test.* TO 'cbio_user'@'localhost'"
mysql --user root --password=password -ve "flush privileges"
mysql --user=cbio_user --password=somepassword cbioportal < ${PORTAL_HOME}/db-scripts/src/main/resources/cgds.sql
mysql --user=cbio_user --password=somepassword cbioportal < ${PORTAL_HOME}/db-scripts/src/main/resources/cgds_im.sql
#It may be necessary to change time_zone that fi tomcat reports 404 error
mysql --verbose --help | grep my.cnf
# set default-time-zone that works for tomcat
echo "[mysqld] \n default-time-zone='+00:00'" >~/my.cnf # my.cnf depends 
### Handling tomcat
#these variables are now defined in my ~/.bash_profile 
#export CATALINA_HOME="/usr/local/opt/tomcat@8/libexec"
#export CATALINA_OPTS='-Dauthenticate=false' #guess this overrides property file
echo 'CATALINA_OPTS="-Dauthenticate=false $CATALINA_OPTS -Ddbconnector=dbcp -XX:MaxPermSize=256m"' >$CATALINA_HOME/bin/setenv.sh
brew services restart tomcat@8 #MUST use brew services to start/stop
wget https://tomcat.apache.org/tomcat-7.0-doc/appdev/sample/sample.war -O $CATALINA_HOME/webapps/sample.war # a small test
ls $CATALINA_HOME/logs #all the logs went here
pushd $CATALINA_HOME/lib
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.15.tar.gz
tar -zxvf mysql-connector-java-8.0.15.tar.gz --strip-components=1 mysql-connector-java-8.0.15/mysql-connector-java-8.0.15.jar
mv mysql-connector-java-8.0.15.jar mysql-connector-java.jar
popd
cp log4j.properties cbioportal/src/main/resources/
patch $CATALINA_HOME/conf/server.xml <${PORTAL_HOME}/../catalina_server.xml.patch

lsof -i:8080 -i:8005 #find competing tomcat instances
brew services restart tomcat@8
#add stuff to $CATALINA_HOME/conf/context.xml # sync password and username with portal.properties.tomcat
#see https://cbioportal.readthedocs.io/en/latest/Deploying.html
### Handling cbioportal
export PORTAL_HOME=$HOME/setup/cbioportal-docker/cbioportal
pushd $PORTAL_HOME 
ln -s portal.properties.tomcat portal.properties
mvn -DskipTests clean install
sudo cp $PORTAL_HOME/portal/target/cbioportal-*.war $CATALINA_HOME/webapps/cbioportal.war
brew services restart mysql@5.7 #MUST use brew services to start/stop
brew services restart comcat@8
```
Do your modification and incrementally build and test with local tomcat.
Use clean to trash intermediatary files.
Keep the cbioportal/db-scripts/src/main/resources/* synced with db_IM/*.
Keep the ../datahub/custom/crc_tcga/* synced with example/*.

### Original README.md by The Hyve ###
# cbioportal-docker @ The Hyve #

The [cBioPortal](https://github.com/cBioPortal/cbioportal) project
documents a setup to deploy a cBioPortal server using Docker,
in [this section of the documentation](https://docs.cbioportal.org/#2-4-docker).
As cBioPortal traditionally did not distinguish between build-time and deploy-time configuration,
the setup documented there builds the application at runtime,
and suggests running auxiliary commands in the same container as the webserver.
The above approach may sacrifice a few advantages of using Docker by going against some of its idioms.
For this reason, the project you are currently looking at documents an alternative setup,
which builds a ready-to-run cBioPortal application into a Docker image.

To get started, download and install Docker from www.docker.com.

[Notes for non-Linux systems](docs/notes-for-non-linux.md)

## Usage instructions ##
This guide supercedes the original Hyve guide if you are using the branch by chaelir

### Step 1 - Setup network ###
Create a network in order for the cBioPortal container and mysql database to communicate.
```
docker network create cbio-net
```

### Step 2 - Run mysql with seed database ###
Start a MySQL server. The command below stores the database in a folder named
`/<path_to_save_mysql_db>/db_files/`. This should be an absolute path.

```
docker run -d --restart=always \
  --name=cbioDB \
  --net=cbio-net \
  -e MYSQL_ROOT_PASSWORD='P@ssword1' \
  -e MYSQL_USER=cbio \
  -e MYSQL_PASSWORD='P@ssword1' \
  -e MYSQL_DATABASE=cbioportal \
  -v /<path_to_save_mysql_db>/db_files/:/var/lib/mysql/ \
  mysql:5.7
```

Download the seed database from the
[cBioPortal Datahub](https://github.com/cBioPortal/datahub/blob/master/seedDB/README.md),
and use the command below to upload the seed data to the server started above.

Make sure to replace
`/<path_to_seed_database>/seed-cbioportal_<genome_build>_<seed_version>.sql.gz`
with the path and name of the downloaded seed database. Again, this should be
an absolute path.

```
docker run \
  --name=load-seeddb \
  --net=cbio-net \
  -e MYSQL_USER=cbio \
  -e MYSQL_PASSWORD='P@ssword1' \
  -v /<path_to_seed_database>/cgds.sql:/mnt/cgds.sql:ro \
  -v /<path_to_seed_database>/seed-cbioportal_<genome_build>_<seed_version>.sql.gz:/mnt/seed.sql.gz:ro \
  mysql:5.7 \
  sh -c 'cat /mnt/cgds.sql | mysql -hcbioDB -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" cbioportal \
      && zcat /mnt/seed.sql.gz |  mysql -hcbioDB -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" cbioportal'
```

Follow the logs of this step to ensure that no errors occur. If any error
occurs, make sure to check it. A common cause is pointing the `-v` parameters
above to folders or files that do not exist.

### Step 3 - Build the Docker image containing cBioPortal ###
Run the command below to build the latest version.

```
docker build -t cbioportal-image https://github.com/thehyve/cbioportal-docker.git
```

If you want to build an image based on a different branch, you can read
[this](docs/adjusting_configuration.md#use-a-different-cbioportal-branch).

### Step 4 - Update the database schema ###

Obtain the [`portal.properties`](https://github.com/thehyve/cbioportal-docker/blob/master/portal.properties).
configuration file for the Docker setup from this repository.

Update the seeded database schema to match the cBioPortal version
in the image, by running the following command. Note that this will
most likely make your database irreversibly incompatible with older
versions of the portal code.

```
docker run --rm -it --net cbio-net \
    -v /<path_to_config_file>/portal.properties:/cbioportal/portal.properties:ro \
    cbioportal-image \
    migrate_db.py -p /cbioportal/portal.properties -s /cbioportal/db-scripts/src/main/resources/migration.sql
```

### Step 5 - Run Session Service containers
First, create the mongoDB database:

```
docker run -d --name=mongoDB --net=cbio-net \
    -e MONGO_INITDB_DATABASE=session_service \
    mongo:4.0
```

Finally, create a container for the Session Service, adding the link to the mongoDB database using `-Dspring.data.mongodb.uri`:

```
docker run -d --name=cbio-session-service --net=cbio-net \
    -e JAVA_OPTS="-Dspring.data.mongodb.uri=mongodb://mongoDB:27017/session-service" \
    thehyve/cbioportal-session-service:cbiov2.1.0
```

### Step 6 - Run the cBioPortal web server ###

Add any cBioPortal configuration in `portal.properties` as appropriate—see
the documentation on the
[main properties](https://github.com/cBioPortal/cbioportal/blob/master/docs/portal.properties-Reference.md)
and the
[skin properties](https://github.com/cBioPortal/cbioportal/blob/master/docs/Customizing-your-instance-of-cBioPortal.md).
Then start the web server as follows.

```
docker run -d --restart=always \
    --name=cbioportal-container \
    --net=cbio-net \
    -v /<path_to_config_file>/portal.properties:/cbioportal/portal.properties:ro \
    -e CATALINA_OPTS='-Xms2g -Xmx4g' \
    -p 8081:8080 \
    cbioportal-image
```

On server systems that can easily spare 4 GiB or more of memory,
set the `-Xms` and `-Xmx` options to the same number. This should
increase performance of certain memory-intensive web services such
as computing the data for the co-expression tab. If you are using
MacOS or Windows, make sure to take a look at [these
notes](docs/notes-for-non-linux.md) to allocate more memory for the
virtual machine in which all Docker processes are running.

cBioPortal can now be reached at <http://localhost:8081/cbioportal/>

Activity of Docker containers can be seen with:
```
docker ps -a
```

## Data loading & more commands ##
For more uses of the cBioPortal image, see [this file](docs/example_commands.md)

To build images from development source
rather than stable releases or snapshots, see
[development.md](docs/development.md).

To Dockerize a Keycloak authentication service alongside cBioPortal,
see [this file](docs/using-keycloak.md).

## Uninstalling cBioPortal ##
First we stop the Docker containers.
```
docker stop cbioDB
docker stop cbioportal-container
```

Then we remove the Docker containers.
```
docker rm cbioDB
docker rm cbioportal-container
```

Cached Docker images can be seen with:
```
docker images
```

Finally we remove the cached Docker images.
```
docker rmi mysql:5.7
docker rmi cbioportal-image
```
