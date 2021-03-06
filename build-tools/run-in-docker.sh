#!/bin/bash

# Create a go workspace in a container, and run any command
#
# $PWD is mounted into the correct go workspace loaction
# All output artifacts are placed in $PWD/_docker_workspace
#

set -e
set -x

CURDIR="$(dirname $BASH_SOURCE)"

. $CURDIR/_build-lib.sh

# To run debug container prepend build_img={latest-debug image id}
: ${build_img:=${BUILD_IMG_TAG}}

# Need to make the directory before docker, to keep it owned by local user
srcdir=src/github.com/F5Networks/cf-bigip-ctlr
wkspace=${PWD}/_docker_workspace
mkdir -p $wkspace/$srcdir

RUN_ARGS=( \
  --rm
  -v $wkspace:/build
  -v $PWD:/build/$srcdir:ro
  --workdir  /build/$srcdir
  -e GOPATH=/build
  -e CLEAN_BUILD
  -e IMG_TAG
  -e BUILD_IMG_TAG
  -e BUILD_VERSION
  -e BUILD_INFO
  -e LOCAL_USER_ID=$(id -u)
  -e BUILDDIR=/build/out
  -e BUILD_VARIANT="${BUILD_VARIANT}"
  -e TRAVIS_REPO_SLUG=$TRAVIS_REPO_SLUG
  -e COVERALLS_TOKEN=$COVERALLS_REPO_TOKEN
)

# Add -it if caller is a terminal
if [ -t 0 ]; then
  RUN_ARGS+=( "-it" )
  RUN_ARGS+=( "--security-opt=seccomp:unconfined" )
fi

# Run the user provided args
docker run "${RUN_ARGS[@]}" "$build_img" "$@"
