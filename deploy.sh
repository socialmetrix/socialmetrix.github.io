#!/usr/bin/env bash
#set -ex

TMP=/tmp
OLD_PWD=$(pwd)
BASE=$(basename ${OLD_PWD})
GH_USER=$(echo ${BASE} | cut -f1 -d'.')

rm -fr ${TMP}/${BASE}
git clone git@github.com:${GH_USER}/${BASE} -b master ${TMP}/${BASE}

jekyll build --destination ${TMP}/${BASE}/

cd ${TMP}/${BASE}/
touch .nojekyll

git add --all
git commit -m "Publishing at $(date)"
git push -f origin master

cd ${OLD_PWD}
rm -fr ${TMP}/${BASE}

echo "Checkout your site at: http://$(cat CNAME)"