The following lines will build the code base from any computer with NVidia-Docker, assuming you are in the directory with the code checkout and want to build in `build`:

To run allen buileder container from a repo container
```bash
docker-compose up -d
```
This container would stay attached to this folder as a volume. You will be able to connect and execute commands inside
```bash
docker-compose exec allen bash
cmake -GNinja -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang -DCMAKE_CUDA_HOST_COMPILER=clang++ -DCMAKE_CUDA_FLAGS="-allow-unsupported-compiler" -DSTANDALONE=ON -DTARGET_DEVICE=${TARGET} -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DSEQUENCE=${SEQUENCE} -DCPU_ARCH=haswell ..
ninja -j 8
./Allen
```

By default, this docker image would compile the code and run it with the input from the "/input" folder. In the command below we mount `input` inside this repository and mount the build folder, so that it caches built files.

> Note: Files inside the build folder would belong to the root user.
