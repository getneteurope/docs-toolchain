#!/bin/bash

DST="public"
REPORTS=('/tmp/rdoc' '/tmp/rubycritic' 'coverage')

if [[ -d "$DST" ]]; then
  rm -rf "$DST"
fi

mkdir -p "$DST"

for f in "${REPORTS[@]}"; do
  mv "$f" "$DST"
done

cp ${DST}/rubycritic/{overview,index}.html
