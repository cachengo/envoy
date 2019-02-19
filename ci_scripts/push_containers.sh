export IMAGE_TAG=$(cat VERSION)
export AARCH=`uname -m`
export IMAGE_NAME=envoy

docker build -t cachengo/$IMAGE_NAME-$AARCH:$IMAGE_TAG -f ci/Dockerfile-envoy-image .
docker push cachengo/$IMAGE_NAME-$AARCH:$IMAGE_TAG
