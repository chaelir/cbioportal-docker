#!/bin/bash
git checkout v1.17h
git merge devel
cp Dockerfile.devel.edit Dockerfile.v1.17h.edit
diff Dockerfile Dockerfile.v1.17h.edit >Dockerfile.v1.17h.patch
cp README.devel.md.edit README.v1.17h.md.edit
diff README.md README.v1.17h.md.edit >README.v1.17h.md.patch
git commit -a
git push
pushd cbioportal
git checkout v1.17h
git merge devel
git commit -a
git push
popd
