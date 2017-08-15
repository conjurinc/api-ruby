#!/bin/bash -ex

function finish {
  docker-compose down -v
}
trap finish EXIT

# Generate reports folders locally
mkdir -p spec/reports features/reports

# Build test container & start the cluster
docker-compose pull postgres possum
docker-compose build --pull
docker-compose up -d

# Delay to allow time for Possum to come up
# TODO: remove this once we have HEALTHCHECK in place
docker-compose run test ci/wait_for_server.sh

api_key=$(docker-compose exec -T possum rails r "print Credentials['cucumber:user:admin'].api_key")

# Execute tests
docker-compose run --rm \
  -e CONJUR_AUTHN_API_KEY="$api_key" \
  test bash -c 'ci/test.sh'

# docker-compose exec -T tests \
#   env CONJUR_AUTHN_API_KEY="$api_key" \
#   bash -c 'ci/test.sh'