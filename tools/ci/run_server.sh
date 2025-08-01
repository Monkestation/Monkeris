#!/bin/bash
set -euo pipefail

tools/deploy.sh ci_test
mkdir -p ci_test/data
# mkdir ci_test/config

#test config
cp tools/ci/ci_config.txt ci_test/config/config.txt
#copy over ranks
cp config/example/admin_ranks.txt ci_test/config/admin_ranks.txt
#this just needs to exist
touch ci_test/config/admins.txt

cd ci_test
DreamDaemon cev_eris.dmb -close -trusted -verbose -params "log-directory=ci"
cd ..
cat ci_test/data/logs/ci/clean_run.lk
