#!/usr/bin/env bash
set -euo pipefail

# Get build scripts and control environment variables
# shellcheck source=ci_utils.sh
source "$(dirname "$0")"/ci_utils.sh

echo "nproc = $(getconf _NPROCESSORS_ONLN) NPROC = ${NPROC}"

if [ "$BUILD_CUDA_MODULE" == "ON" ] &&
    ! nvcc --version 2>/dev/null | grep -q "release ${CUDA_VERSION[1]}"; then
    install_cuda_toolkit with-cudnn purge-cache
    nvcc --version
fi

if [ "$BUILD_CUDA_MODULE" == "ON" ]; then
    install_python_dependencies with-unit-test with-cuda purge-cache
else
    install_python_dependencies with-unit-test purge-cache
fi

echo "using python: $(which python)"
python --version
echo -n "Using pip: "
python -m pip --version
echo -n "Using pytest:"
python -m pytest --version
echo "using cmake: $(which cmake)"
cmake --version

build_all

echo "Building examples iteratively..."
make VERBOSE=1 -j"$NPROC" build-examples-iteratively
echo

echo "Running Open3D C++ unit tests..."
run_cpp_unit_tests

echo "Test building a C++ example with installed Open3D..."
test_cpp_example "${runExample:=ON}"
echo

echo "Test uninstalling Open3D..."
make uninstall
