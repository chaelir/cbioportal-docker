#!/bin/bash

### NOTE: this requires pre-installed of docker ###

mkdir -p $HOME/setup
cd  $HOME/setup
xcode-select --install
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install git || brew upgrade git
brew install git-lfs || brew upgrade git-lfs
git lfs install

git clone https://github.com/chaelir/datahub.git || true
pushd datahub
git checkout cbiov2.1.0
popd

git clone https://github.com/chaelir/cbioportal-docker.git || true
pushd cbioportal-docker
git checkout cbiov2.1.0

./cbio.deploy.sh create_network release-2.1.0 | bash
./cbio.deploy.sh run_mysql release-2.1.0 | bash
./cbio.deploy.sh seed_mysql release-2.1.0 | bash
./cbio.deploy.sh build_cbio release-2.1.0 | bash
./cbio.deploy.sh run_cbio release-2.1.0 | bash
./cbio.deploy.sh populate_cbio release-2.1.0 | bash
./cbio.deploy.sh rerun_cbio release-2.1.0 | bash

#Now: open brower at http://localhost:8882/cbioportal/ to view the portal
