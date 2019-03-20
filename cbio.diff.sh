#!/bin/bash

### brew install diffutils required for the --no-dereference option
diff -q -r --no-dereference -X cbio.diff.exclude cbioportal cbioportal-hyve | sort >mine-vs-hyve.diff
diff -N -r --no-dereference -X cbio.diff.exclude cbioportal cbioportal-hyve >mine-vs-hyve.patch
