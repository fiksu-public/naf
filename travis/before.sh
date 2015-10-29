#!/bin/sh

cd spec/dummy/
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake db:test:clone_structure
