#!/bin/bash -e

rake="bundle exec rake"

cd spec/dummy

# Bring in the initializer

if [ $SPEC_GROUP == 'non_primary_database' ]
then
  echo 'Testing non primary database install'
  cp config/database-non_primary.yml config/database.yml
  cp app/models/other/base.rb.sample app/models/other/base.rb
  cp config/initializers/naf.rb.non_primary config/initializers/naf.rb
  $rake naf:install:migrations naf:isolate:migrations db:create:all naf:db:migrate naf:janitor:infrastructure naf:db:test:clone_structure
else
  cp config/database-primary.yml config/database.yml
  cp config/initializers/naf.rb.primary config/initializers/naf.rb
  $rake naf:install:migrations db:create db:migrate naf:janitor:infrastructure db:test:clone_structure
fi

cd ../..

$rake spec

