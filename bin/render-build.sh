#!/usr/bin/env bash
set -o errexit
set -o nounset

: "${DATABASE_URL:?Set DATABASE_URL to the existing Render PostgreSQL database}"
export RAILS_ENV="${RAILS_ENV:-production}"
if [ "$RAILS_ENV" != "production" ]; then
  echo "This script must run in the production environment." >&2
  exit 1
fi

bundle install
bundle exec rails assets:precompile
bundle exec rails runner '
  config = ActiveRecord::Base.connection_db_config.configuration_hash
  abort "Refusing migration outside the swexe_l5 schema" unless config[:schema_search_path] == "swexe_l5"

  connection = ActiveRecord::Base.connection
  connection.execute("CREATE SCHEMA IF NOT EXISTS swexe_l5")
  abort "The swexe_l5 schema is not active" unless connection.select_value("SELECT current_schema()") == "swexe_l5"
'
bundle exec rails db:migrate
