#!/bin/bash

set -e

tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
repo_name="bridgetown-automation-docker-compose"
repo_url="https://github.com/ParamagicDev/$repo_name"
branch="${1:-master}"
docker_tag="bridgetown-automation-docker:latest"
PROJECT_TYPE=$PROJECT_TYPE
DESTINATION=$DESTINATION
DOCKER_RUBY_VERSION=$DOCKER_RUBY_VERSION
DOCKER_DISTRO=$DOCKER_DISTRO
CI=$CI

main() {
  printf "Installing Bridgetown via Docker...\n"
  check_dependencies
  clone_repo
  ask_for_destination
  ask_for_project_type
  build_docker_image
  run_docker_container
  closing_message
}

# Check if docker exists
check_dependencies() {
  command -v docker || (echo "Docker executable not found" && exit 1)
  command -v docker-compose || (echo "Docker Compose executable not found" && exit 1)
  command -v git || (echo "git executable not found" && exit 1)
}

# Pull down Dockerfile to a tempdir
clone_repo() {
  git clone "$repo_url" "$tmp_dir"
  cd "$tmp_dir" && git checkout "$branch" && cd -
}

ask_for_destination() {
  if [ -z "$DESTINATION" ]; then
    printf "What is the directory of your bridgetown project?\n" && \
    read DESTINATION
    mkdir -p "$DESTINATION" || (echo "Unable to create new directory" && exit 1)
  fi
}

ask_for_project_type() {
  # make case matching insensitive
  shopt -s nocasematch

  while true; do
    [ "$PROJECT_TYPE" = "existing" ] && break
    [ "$PROJECT_TYPE" = "new" ] && break
    printf "Is this for a new or existing Bridgetown project? [(N)ew, (E)xisting]\n"
    read PROJECT_TYPE

    if [ "$PROJECT_TYPE" = "existing" ] || [ "$PROJECT_TYPE" = "e" ]; then
      PROJECT_TYPE="existing"
      break
    elif [ "$PROJECT_TYPE" = "new" ] || [ "$PROJECT_TYPE" = "n" ]; then
      PROJECT_TYPE="new"

      [ "$(ls -A $DESTINATION)" ] && echo "Directory not empty. Aborting..." && exit 1
      break
    fi
  done

  # turn case sensitive matching back on
  shopt -u nocasematch
}

copy_gemfile() {
  if [ "$PROJECT_TYPE" = "new" ]; then
    echo "source 'https://rubygems.org'" > "$DESTINATION/Gemfile"
    echo "gem 'bridgetown'" >> "$DESTINATION/Gemfile"
  fi
}

build_docker_image() {
  # env vars
  source "$tmp_dir/docker.env"

  copy_gemfile

  printf "Building your docker image...\n\n"
  source "$tmp_dir/docker.env"
  docker build  -t $docker_tag \
                -f $tmp_dir/Dockerfile \
                --build-arg DOCKER_USER \
                --build-arg USER_ID \
                --build-arg GROUP_ID \
                --build-arg APP_DIR \
                "$DESTINATION"

  printf "Successfully built your image for Bridgetown.\n\n"
}

docker_run() {
  if [ "$CI" = "true" ]; then
  docker run -e DOCKER_RUBY_VERSION -e DOCKER_DISTRO --rm \
               -v "$(realpath $DESTINATION)":"$APP_DIR" \
               -u $USER_ID:$GROUP_ID "$docker_tag" \
               bash -c "$1"
  else
    docker run -e DOCKER_RUBY_VERSION -e DOCKER_DISTRO --rm \
               -v "$(realpath $DESTINATION)":"$APP_DIR" \
               -u $USER_ID:$GROUP_ID -it "$docker_tag" \
               bash -c "$1"
  fi
}

run_docker_container() {
  if [ "$PROJECT_TYPE" = "new" ]; then
    docker_run "DOCKER_RUBY_VERSION=$DOCKER_RUBY_VERSION DOCKER_DISTRO=$DOCKER_DISTRO \
                bundle install && bundle exec bridgetown new . --apply=\"$repo_url/tree/$branch\" --force"
  elif [ "$PROJECT_TYPE" = "existing" ]; then
    docker_run "bundle install && bundle exec bridgetown apply $repo_url/tree/$branch"
  fi
  
}

closing_message() {
  printf "Successfully added Docker to your bridgetown project\n"
  printf "To use docker in your new project simply do the following:\n\n"
  printf "cd $DESTINATION && source docker.env && docker-compose up --build"
  
}

main
