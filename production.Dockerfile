# syntax=docker/dockerfile:1

FROM ruby:3.2.0-slim as base

WORKDIR /rails

ENV RAILS_ENV=production \
  LANG=C.UTF-8 \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3 \
  BUNDLE_PATH="/usr/local/bundle"


# Throw-away build stage to reduce size of final image
FROM base as build

RUN apt-get update -qq && apt-get install -yq --no-install-recommends \
  build-essential \
  gnupg2 \
  libpq-dev \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN gem update --system && gem install bundler

COPY Gemfile Gemfile.lock ./

RUN bundle config frozen true \
  && bundle config jobs 4 \
  && bundle config deployment true \
  && bundle config without 'development test' \
  && bundle install \
  && bundle exec bootsnap precompile --gemfile

COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Final stage for app image
FROM base

# Install packages needed for deployment
RUN apt-get update -qq && apt-get install -yq --no-install-recommends \
  libpq-dev \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN useradd rails --home /rails --shell /bin/bash && \
  chown -R rails:rails db log storage tmp
USER rails:rails

# TODO: migrate/consolidate to have all database migrations in here
# Entrypoint prepares the database.
# ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Run database migrations when deploying to Render. It is not great, maybe there's a better way?
# https://community.render.com/t/release-command-for-db-migrations/247/6
ARG RENDER
ARG DATABASE_URL
ARG SECRET_KEY_BASE
RUN if [ -z "$RENDER" ]; then echo "var is unset"; else bin/rails db:migrate; fi

# Start Server
EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
