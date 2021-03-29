#!/bin/bash

RAILS_ENV='production' rake db:create &&
RAILS_ENV='production' rake db:migrate &&
RAILS_ENV='production' rake db:seed &&
RAILS_ENV='production' RAILS_SERVE_STATIC_FILES='true' rake assets:precompile
