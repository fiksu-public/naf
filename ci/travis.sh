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
  $rake naf:install:migrations
  $rake naf:isolate:migrations
  $rake db:create:all
  $rake naf:db:migrate
  $rake naf:janitor:infrastructure
  $rake naf:db:test:clone_structure
else
  echo 'Testing primary database install'
  cp config/database-primary.yml config/database.yml
  cp config/initializers/naf.rb.primary config/initializers/naf.rb
  $rake naf:install:migrations
  $rake db:create
  $rake db:migrate
  $rake naf:janitor:infrastructure
  $rake db:test:clone_structure
fi

cd ../..

$rake spec
