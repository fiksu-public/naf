#!/bin/bash -e

rake="bundle exec rake"

cd spec/dummy

$rake db:create db:migrate naf:janitor:infrastructure db:test:clone_structure

cd ../..

$rake spec

