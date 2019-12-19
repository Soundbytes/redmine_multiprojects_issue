#/bin/bash

set -e

if [[ ! "$TESTSPACE" = /* ]] ||
   [[ ! "$PATH_TO_REDMINE" = /* ]] ||
   [[ ! "$REDMINE_VER" = * ]] ||
   [[ ! "$NAME_OF_PLUGIN" = * ]] ||
   [[ ! "$PATH_TO_PLUGIN" = /* ]];
then
  echo "You should set"\
       " TESTSPACE, PATH_TO_REDMINE, REDMINE_VER"\
       " NAME_OF_PLUGIN, PATH_TO_PLUGIN"\
       " environment variables"
  echo "You set:"\
       "$TESTSPACE"\
       "$PATH_TO_REDMINE"\
       "$REDMINE_VER"\
       "$NAME_OF_PLUGIN"\
       "$PATH_TO_PLUGIN"
  exit 1;
fi

export RAILS_ENV=test

export REDMINE_GIT_REPO=git://github.com/redmine/redmine.git
export REDMINE_GIT_TAG=$REDMINE_VER
export BUNDLE_GEMFILE=$PATH_TO_REDMINE/Gemfile

# checkout redmine
git clone $REDMINE_GIT_REPO $PATH_TO_REDMINE
cd $PATH_TO_REDMINE
if [ ! "$REDMINE_GIT_TAG" = "master" ];
then
  git checkout -b $REDMINE_GIT_TAG origin/$REDMINE_GIT_TAG
fi

# create a link to the backlogs plugin
ln -sf $PATH_TO_PLUGIN plugins/$NAME_OF_PLUGIN

# Add other plugins dependencies
git clone https://github.com/jbbarth/redmine_base_deface.git plugins/redmine_base_deface
git clone https://github.com/nanego/redmine_base_stimulusjs.git plugins/redmine_base_stimulusjs

mv $TESTSPACE/database.yml.travis config/database.yml
mv $TESTSPACE/additional_environment.rb config/

# install gems
bundle install

# run redmine database migrations
bundle exec rails db:migrate

# run plugin database migrations
bundle exec rails redmine:plugins:migrate

# install redmine database
bundle exec rails redmine:load_default_data REDMINE_LANG=en

bundle exec rails db:structure:dump
bundle exec rails db:fixtures:load

# run tests
# bundle exec rake TEST=test/unit/role_test.rb
bundle exec rails test
bundle exec rails redmine:plugins:test NAME=$NAME_OF_PLUGIN
