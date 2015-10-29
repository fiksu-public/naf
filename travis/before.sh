#!/bin/sh

cd spec/dummy/
cp config/database-primary.yml config/database.yml
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake db:test:clone_structure
