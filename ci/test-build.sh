#!/bin/bash -e

echo 'Dropping your naf_development database if it exists'

psql -U postgres -c "drop database if exists naf_development"
psql -U postgres -c "drop database if exists primary_development"

echo 'Removing existing migration in dummy application'

rm -f spec/dummy/app/models/other/base.rb

rm -rf spec/dummy/db/naf

rm -f spec/dummy/db/migrate/*.rb

./ci/travis.sh

