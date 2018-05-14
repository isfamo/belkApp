# Solution Engineering Rails/Angular Template

## Intro

This template encapsulates both a fully configured Rails backend (salsify gems, delayed jobs, salsify omniauth, ect) and a fully configured Angular front end compatible with Salsify authentication.

## Setup

### Rails Setup

`gem install bundler`

`bundle install`

Make sure to updated your database name in `database.yml`

`bundle exec rake db:create`

If you’re having trouble creating a DB and getting error that look like this: `PG::ConnectionBad: FATAL:  role "username" does not exist`, follow the these steps:

```
psql -U postgres
CREATE ROLE username;
ALTER ROLE "username" WITH LOGIN;
ALTER ROLE "username" WITH CREATEDB;
```

### Remove DB

If you don't require a DB, follow these steps:

* Comment out `Rails.application.config.active_record.belongs_to_required_by_default = true` from `config/initializers/new_framework_defaults.rb`
* Remove the gem `pg` from the `Gemfile`
* Replace `rspec-rails` gem with just `rspec` and bundle
* Remove all `db-cleaner` references in `spec_helper.rb`
* Remove `require 'rspec/rails'` from `rails_helper.rb` and comment out all config options
* Remove `database.yml` from `config/initializers`
* Comment out `ActiveRecord::Migration.maintain_test_schema!` from `config/rails_helper.rb`
* Comment out `config.active_record.dump_schema_after_migration = false` from `config/production.rb`
* Comment out `config.active_record.migration_error = :page_load` from `config/development.rb`
* Replace `require 'rails/all'` in in `config/application.rb` with:
```
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'sprockets/railtie'
require 'rails/test_unit/railtie'
```


### Angular Setup

`cd client`

Assuming node, npm, grunt, and bower are installed:

switch to latest version of node: `nvm use node`

install npm, grunt, and bower:
`npm install -g bower --save`
`npm install -g grunt --save`
`npm install -g grunt-cli --save`

install dependencies:

`npm install connect-modrewrite --save`

`npm install grunt-include-source --save`

`npm install karma --save`

`npm install grunt-connect-proxy --save`

`npm install grunt-shell --save`

`npm install grunt-shell-spawn --save`

install npm packages: `npm install`

install bower components: `bower install`

To run locally, following either step:

#### Grunt Serve

Open two terminal windows.

Window 1: `rails s`

Window 2: `cd client: grunt serve`

visit: `localhost:9000`

#### Grunt Build

Open two terminal windows.

Window 1: `cd client: grunt build`

Window 2: `rails s`

visit: `localhost:3000`

### Delayed Jobs

To enable Delayed Jobs, run the following:

```
  rails g delayed_job:active_record
  rake db:migrate
```

## Deploy to Heroku

If you're using the angular front end, one step is required before pushing to heroku. We need to tell heroku to build the front end client as part of the push. To enable, run the following:

`heroku buildpacks:add --index 1 https://github.com/cgrdavies/heroku-buildpack-webapp-client.git`

### Doorkeeper

You'll need to setup doorkeeper credentials and use in Heroku for this to work in production. Steps to follow on https://salsify.atlassian.net/wiki/display/ENG/How+to+OAuth
