#!/bin/bash

(cd $DEVSRC; bundle cache)

rm -f *gem *tar.bz2
cp $DEVSRC/Gemfile .
cp $DEVSRC/Gemfile.lock .
cp $DEVSRC/vendor/cache/*gem .
> Source.new

c=3
for src in $(cd $DEVSRC; find vendor/cache/  -mindepth 1 -maxdepth 1 -type d); do
   tar cfj $(basename $src).tar.bz2 -C $DEVSRC $src;
   echo Source$((c++)): $(basename $src).tar.bz2 >> Source.new
done
for g in *gem; do echo Source$((c++)): $(basename $g) >> Source.new ; done; 

sed -i '/^Source2:/,/# SourceEnd/ {//!d}; /^Source2:/r Source.new' *.spec
rm Source.new
