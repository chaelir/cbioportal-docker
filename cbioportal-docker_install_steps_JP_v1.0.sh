#!/bin/bash
# turn on echoing of each ran command
set -x
stage=$1
if [ -z $stage ]; then echo "input a stage: clone run_mysql, pop_mysql, build_cbio, or run_cbio"; exit; fi

build_root="$HOME/Projects/cBIO/setup/"
cbioportal_docker_version="v2.1.0"
cbioportal_docker_name="cbioportal_docker_${cbioportal_docker_version}"
cbioportal_build_name="cbioportal_${cbioportal_docker_version}"
datahub_priv_branch="jp_imh"
cbioportal_docker_branch=dev_jp

########################################################
# CLONE CBIOPORTALS AND DATAHUBS
########################################################
if [ $stage == 'clone' ]; then
  cd ${build_root}
  git clone https://github.com/chaelir/cbioportal-docker.git ${cbioportal_docker_name}
  git checkout --track origin/${cbioportal_docker_branch}
  echo "*** Finished cloning ${cbioportal_docker_name}, checked out branch ${cbioportal_docker_branch} ***"
  cd ${cbioportal_docker_name} 
  # clone the portal to add and build inside the cbioportal-docker
  git clone --depth 1 -b ${cbioportal_docker_version} https://github.com/cBioPortal/cbioportal.git ${cbioportal_build_name}
  echo "*** Finished cloning ${cbioportal_build_name} ***"
  # datahub(s)
  cd ${build_root}
  git clone https://github.com/cBioPortal/datahub.git datahub
  echo "*** Finished cloning public datahub ***"
  git clone --depth 1 -b ${datahub_priv_branch} https://github.com/chaelir/datahub_priv.git datahub_priv
  echo "*** Finished cloning private public datahub ***"
  ls -al .
fi




