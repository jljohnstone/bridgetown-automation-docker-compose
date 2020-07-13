#!/bin/bash

set -u

printf "Installing Bridgetown via Docker...\n"

# Check if docker exists
command -v docker -v || echo "Docker executable not found" && exit 1
command -v "docker-compose -v" || echo "Docker Compose executable not found" && exit 1
git --version || echo "git executable not found" && exit 1

# Pull down Dockerfile to a tempdir
tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)

repo_name="bridgetown-automation-docker-compose"
repo_url="https://github.com/ParamagicDev/$repo_name.git"

# Pull down files related to docker.
git clone "$repo_url" "$tmp_dir" --quiet

source "$tmp_dir/docker.env"

docker_tag="bridgetown-automation-docker:latest"

printf "Building your docker image\n\n"
docker build -t "$docker_tag" \
             -f "$tmp_dir/Dockerfile" \
             --target builder \
             --build-arg USER_ID GROUP_ID DOCKER_USER APP_DIR

# Clean up
rm -rf "$tmp_dir"

printf "Successfully built your image for Bridgetown.\n"
printf "To add Docker to your Bridgetown project run the following:\n"
printf "\nFor a new project run:"
printf "\ndocker run -it %s bridgetown new <newsite> --apply=\"%s\"" "$docker_tag" "$repo_url"
printf "\n\n"
printf "\nFor an existing project run:"
printf "docker run -it %s [bundle exec] bridgetown apply %s" "$docker_tag" "$repo_url"
printf "\n"
