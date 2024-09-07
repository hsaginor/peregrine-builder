#!/bin/bash

PEREGRINE_BUILDER_DIR=peregrine-builder/builder/src
SLING_ORG_APACHE_SLING_STARTER_DIR=sling-org-apache-sling-starter/src

if [ "$(basename $(pwd))" == "peregrine-builder" ] && [ -d "builder" ]; then
  echo "Moving to parent directory"
  cd ..
fi

if [ ! -d "diffs" ]; then
  echo "Creating diffs directory"
  mkdir diffs
fi

if [ ! -d "sling-org-apache-sling-starter" ]; then
  echo "Cloning sling-org-apache-sling-starter"
  git clone https://github.com/apache/sling-org-apache-sling-starter.git
fi

diff -r -q $SLING_ORG_APACHE_SLING_STARTER_DIR $PEREGRINE_BUILDER_DIR | grep -v ".json" | grep -v "Only in $SLING_ORG_APACHE_SLING_STARTER_DIR" | grep -v "Only in $PEREGRINE_BUILDER_DIR" | awk '{print $2}' > diffs/diff-list-other.txt
diff -r -q $SLING_ORG_APACHE_SLING_STARTER_DIR $PEREGRINE_BUILDER_DIR | grep "Only in $PEREGRINE_BUILDER_DIR" > diffs/only-peregrine.txt
diff -r -q $SLING_ORG_APACHE_SLING_STARTER_DIR $PEREGRINE_BUILDER_DIR | grep "Only in $SLING_ORG_APACHE_SLING_STARTER_DIR" > diffs/only-sling-starter.txt

echo "Comparing JSON files in $SLING_ORG_APACHE_SLING_STARTER_DIR and $PEREGRINE_BUILDER_DIR and applying patchs..."

diff -r -q $SLING_ORG_APACHE_SLING_STARTER_DIR $PEREGRINE_BUILDER_DIR | grep ".json" | grep -v "Only in $SLING_ORG_APACHE_SLING_STARTER_DIR" | grep -v "Only in $PEREGRINE_BUILDER_DIR" | awk '{print $2}' > diffs/diff-list.txt

while read line; do
  FILE_NAME=$(basename $line)
  REL_PATH=${line/$SLING_ORG_APACHE_SLING_STARTER_DIR/}
  echo $PEREGRINE_BUILDER_DIR/$REL_PATH
  diff $PEREGRINE_BUILDER_DIR$REL_PATH $line > diffs/$FILE_NAME.diff
  git diff $PEREGRINE_BUILDER_DIR$REL_PATH $line > diffs/$FILE_NAME.patch
  # in file diffs/$FILE_NAME.patch replace $SLING_ORG_APACHE_SLING_STARTER_DIR with $PEREGRINE_BUILDER_DIR
  sed -i '' 's/sling-org-apache-sling-starter\/src/peregrine-builder\/builder\/src/g' diffs/$FILE_NAME.patch
  git apply diffs/$FILE_NAME.patch
  diff $PEREGRINE_BUILDER_DIR$REL_PATH $line > diffs/$FILE_NAME.diff.after
done < diffs/diff-list.txt

while read line; do
  FILE_NAME=$(basename $line)
  REL_PATH=${line/$SLING_ORG_APACHE_SLING_STARTER_DIR/}
  echo $PEREGRINE_BUILDER_DIR/$REL_PATH
  diff $PEREGRINE_BUILDER_DIR$REL_PATH $line > diffs/$FILE_NAME.diff
done < diffs/diff-list-other.txt