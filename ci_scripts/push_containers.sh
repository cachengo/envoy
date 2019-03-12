export IMAGE_TAG=$(cat VERSION)
export AARCH=`uname -m`
export IMAGE_NAME=envoy

if [ "$(uname -m)" == 'aarch64' ]; then
  cd ci/build_container
  TRAVIS_COMMIT=bazel052 ./docker_build.sh
  cd ../..
  IMAGE_ID=bazel052 ENVOY_DOCKER_BUILD_DIR="${WORKSPACE}@tmp/envoy-docker" ./ci/run_envoy_docker.sh \
    './ci/do_ci.sh bazel.release.server_only'
  mkdir -p build_release
  cp ${WORKSPACE}@tmp/envoy-docker/envoy/source/exe/envoy build_release/
  rm -rf /tmp/envoy-docker
  docker build -t cachengo/$IMAGE_NAME-$AARCH:$IMAGE_TAG -f ci/Dockerfile-envoy-image .
else
  docker pull lyft/envoy:$IMAGE_TAG
  docker tag lyft/envoy:$IMAGE_TAG cachengo/$IMAGE_NAME-$AARCH:$IMAGE_TAG
fi

docker push cachengo/$IMAGE_NAME-$AARCH:$IMAGE_TAG
