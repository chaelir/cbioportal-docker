#!/bin/bash
set -x
mysql --user root --password=password -ve "DROP DATABASE IF EXISTS cgds_mock; CREATE DATABASE cgds_mock"
mysql --user root --password=password -ve "DROP USER IF EXISTS 'cbio_mock'@'localhost'; CREATE USER 'cbio_mock'@'localhost' IDENTIFIED BY 'somepassword'"
mysql --user root --password=password -ve "GRANT ALL ON cgds_mock.* TO 'cbio_mock'@'localhost'"
mysql --user root --password=password -ve "flush privileges"
#mysql --user cbio_mock --password=somepassword cgds_mock <../cbioportal/db-scripts/src/main/resources/cgds_clean.sql
mysql --user cbio_mock --password=somepassword cgds_mock <../cbioportal/db-scripts/src/main/resources/cgds.sql
mysql --user cbio_mock --password=somepassword cgds_mock <../cbioportal/db-scripts/src/main/resources/cgds_im.sql
mysql --user cbio_mock --password=somepassword cgds_mock <../cbioportal/core/src/test/resources/seed_mini.sql
mysql --user cbio_mock --password=somepassword cgds_mock <../cbioportal/core/src/test/resources/cgds_im_test_seed_mini.sql
#mysql --user cbio_mock --password=somepassword cgds_mock <../cbioportal/db-scripts/src/main/resources/cgds_clean.sql
#mysql --user cbio_mock --password=somepassword cgds_mock <../cbioportal/db-scripts/src/main/resources/cgds.sql
#mysql --user cbio_mock --password=somepassword cgds_mock <../cbioportal/db-scripts/src/main/resources/cgds_im.sql
#mysql --user cbio_mock --password=somepassword cgds_mock <../cbioportal/core/src/test/resources/seed_mini.sql
#mysql --user cbio_mock --password=somepassword cgds_mock <../cbioportal/core/src/test/resources/cgds_im_test_seed_mini.sql
