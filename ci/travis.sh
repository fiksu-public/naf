#!/bin/bash -e

rake="bundle exec rake"

cd spec/dummy

$rake db:create
$rake db:migrate
$rake naf:janitor:infrastructure
$rake db:test:clone_structure

cd ../..

$rake spec

