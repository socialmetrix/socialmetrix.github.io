#!/usr/bin/env bash
#set -x

### FUNCTIONS
#
function urlencode () {
  ENCODED=$(echo -n "$*" | perl -pe's/([^-_.~A-Za-z0-9]+)/-/sg');
  echo ${ENCODED}
}

TITLE=$*
WHEN=$(date -u +'%Y-%m-%d')

FILENAME="${WHEN}-$(urlencode ${TITLE}).md"

TEMPLATE=$(cat <<EOF
---
layout: post
title: ${TITLE}
tags: []
author: ${USER}
---


EOF
)

echo "${TEMPLATE}" > _posts/${FILENAME}
echo "Happy Blogging"

if [[ -n ${EDITOR} ]]; then
  ${EDITOR} _posts/${FILENAME} &
else
  echo "Go ahead and write your post: _posts/${FILENAME}"
fi

jekyll --watch serve
