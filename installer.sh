#!/bin/bash

set -eu

printf "Installing Bridgetown via Docker...\n"

# Check if docker exists
command -v docker || (echo "Docker executable not found" && exit 1)
command -v docker-compose || (echo "Docker Compose executable not found" && exit 1)
command -v git || (echo "git executable not found" && exit 1)

# Pull down Dockerfile to a tempdir
tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)

repo_name="bridgetown-automation-docker-compose"
repo_url="https://github.com/ParamagicDev/$repo_name"

# Pull down files related to docker.
git clone "$repo_url" "$tmp_dir"
branch="${1:-master}"

cd "$tmp_dir" && git checkout "$branch" && cd -

# turn case sensitive matching back on
shopt -u nocasematch

source "$tmp_dir/docker.env"
docker_tag="bridgetown-automation-docker:latest"

printf "Building your docker image...\n\n"
source "$tmp_dir/docker.env"
docker build  -t $docker_tag \
              -f $tmp_dir/Dockerfile \
              --target builder \
              "$tmp_dir"

# Clean up
rm -rf "$tmp_dir"

printf "Successfully built your image for Bridgetown.\n\n"

[ -z "$DESTINATION" ] && printf "What is the directory of your bridgetown project?\n" && read DESTINATION

while true; do
  [ "$PROJECT_TYPE" = "existing" ] || break
  [ "$PROJECT_TYPE" = "new" ] || break
  printf "Is this for a new or existing Bridgetown project? [(N)ew, (E)xisting]\n"
  read PROJECT_TYPE

  # make case matching insensitive
  shopt -s nocasematch
  if [ "$PROJECT_TYPE" = "existing" ] || [ "$PROJECT_TYPE" = "e" ]; then
    PROJECT_TYPE="existing"
    break
  elif [ "$PROJECT_TYPE" = "new" ] || [ "$PROJECT_TYPE" = "n" ]; then
    PROJECT_TYPE="new"
    break
  fi
done

if [ "$PROJECT_TYPE" = "new" ]; then
  docker run --rm -v ".:$APP_DIR" -it "$docker_tag" bash -c "gem install bridgetown && \
             bridgetown new $DESTINATION --apply=$repo_url"
elif [ "$PROJECT_TYPE" = "existing" ]; then
  cd "$DESTINATION" || (echo "Unable to locate directory." && exit 1)
  docker run --rm -v ".:$APP_DIR" -it "$docker_tag" "bundle exec bridgetown apply $repo_url"
fi

printf "Successfully added Docker to your bridgetown project\n"
printf "To use docker in your new project simply do the following:\n\n"
printf "cd $DESTINATION && source docker.env && docker-compose up --build"
