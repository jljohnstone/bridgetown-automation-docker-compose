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
repo_url="https://github.com/ParamagicDev/$repo_name.git"

# Pull down files related to docker.
git clone "$repo_url" "$tmp_dir" --quiet
branch="$1"
cd "$tmp_dir" && git checkout "$branch" && cd -


# turn case sensitive matching back on
shopt -u nocasematch


source "$tmp_dir/docker.env"

docker_tag="bridgetown-automation-docker:latest"

printf "Building your docker image...\n\n"
source "$tmp_dir/docker.env"
docker build -t $docker_tag \
             -f "$tmp_dir/Dockerfile" \
             --target builder \
             "$tmp_dir"

# Clean up
rm -rf "$tmp_dir"

printf "Successfully built your image for Bridgetown.\n\n"

printf "What is the directory of your bridgetown project?\n"
read destination

while true; do
  printf "Is this for a new or existing Bridgetown project? [(N)ew, (E)xisting]\n"
  read project_type

  # make case matching insensitive
  shopt -s nocasematch
  if [ "$project_type" == "existing" ] || [ "$project_type" == "e" ]; then
    project_type="existing"
    break
  elif [ "$project_type" == "new" ] || [ "$project_type" == "n" ]; then
    project_type="new"
    break
  fi
done

if [ "$project_type" == "new" ]; then
  docker run --rm -it "$docker_tag" gem install bridgetown
  docker run --rm -it "$docker_tag" bridgetown new "$destination" \
             --apply="$repo_url"
elif [ "$project_type" == "existing" ]; then
  cd "$destination" || (echo "Unable to locate directory." && exit 1)
  docker run --rm -it "$docker_tag" bundle exec bridgetown apply "$repo_url"
fi

printf "Successfully added Docker to your bridgetown project\n"
printf "To use docker in your new project simply do the following:\n\n"
printf "cd $destination && source docker.env && docker-compose up --build"
