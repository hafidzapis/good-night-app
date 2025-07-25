FROM ruby:3.1.2-slim

# Install essential packages for building native extensions and PostgreSQL client
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
  build-essential \
  libpq-dev \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .
COPY docker/entrypoint.sh docker/entrypoint.sh
RUN chmod +x docker/entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["docker/entrypoint.sh"]
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
