#!/bin/bash

set -e

# Setup basic requirements and install them.
apt-get update
apt-get install -y wget software-properties-common make cmake git python python-pip \
  bc libtool automake zip time golang g++ gdb strace
# clang head (currently 5.0)
wget -O - http://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
apt-add-repository "deb [arch=amd64] http://apt.llvm.org/xenial/ llvm-toolchain-xenial-5.0 main"
apt-get update
apt-get install -y clang-5.0 clang-format-5.0
# Bazel and related dependencies.
apt-get install -y openjdk-8-jdk curl

if [ "$(uname -m)" == 'aarch64' ]; then
  BAZEL_VERSION=0.5.2
  apt install patch unzip wget
  mkdir /bazel && cd /bazel
  wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip
  unzip bazel*zip
  # Apply workaround for missing locale
  patch -p1 < <(curl https://github.com/bazelbuild/bazel/commit/860af5be10b6bad68144d9d2d34173e86b40268c.patch)
  env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" bash ./compile.sh
  cp /bazel/output/bazel /usr/bin/bazel
  chmod 755 /usr/bin/bazel
  cd - && rm -rf /bazel
else
  echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list
  curl https://bazel.build/bazel-release.pub.gpg | apt-key add -
  apt-get update
  apt-get install -y bazel
fi
rm -rf /var/lib/apt/lists/*

# virtualenv
pip install virtualenv

# buildifier
export GOPATH=/usr/lib/go
go get -d github.com/bazelbuild/buildifier/buildifier
# GO in Ubuntu Xenial does not support features used by newer buildifier
cd "$GOPATH/src/github.com/bazelbuild/buildifier/buildifier"
git checkout 0.4.5
go install
cd -

# GCC for everything.
export CC=gcc
export CXX=g++
CXX_VERSION="$(${CXX} --version | grep ^g++)"
if [[ "${CXX_VERSION}" != "g++ (Ubuntu 5.4.0-6ubuntu1~16.04.4) 5.4.0 20160609" ]]; then
  echo "Unexpected compiler version: ${CXX_VERSION}"
  # exit 1
fi

export THIRDPARTY_DEPS=/tmp
export THIRDPARTY_SRC=/thirdparty
DEPS=$(python <(cat target_recipes.bzl; \
  echo "print ' '.join(\"${THIRDPARTY_DEPS}/%s.dep\" % r for r in set(TARGET_RECIPES.values()))"))

# TODO(htuch): We build twice as a workaround for https://github.com/google/protobuf/issues/3322.
# Fix this. This will be gone real soon now.
export THIRDPARTY_BUILD=/thirdparty_build
export CPPFLAGS="-DNDEBUG"
echo "Building opt deps ${DEPS}"
"$(dirname "$0")"/build_and_install_deps.sh ${DEPS}
