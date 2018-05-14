# Belk

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

### Delayed Jobs

To enable Delayed Jobs, run the following:

```
  rails g delayed_job:active_record
  rake db:migrate
```
