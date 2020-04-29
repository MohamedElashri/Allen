The following lines will build the code base from any computer with NVidia-Docker, assuming you are in the directory with the code checkout and want to build in `build`:

First, build the docker image containing your code. If you change the code you should rebuild the image, so that it picks up the changes.

> Note: If you are working in a shared environment you might have a problem with a name collision, please consider adding $USER to the image name.

To build it yourself please run
```bash
docker build -t lhcb/allen:latest .
```

By default, this docker image would compile the code and run it with the input from the "/input" folder. In the command below we mount `input` inside this repository and mount the build folder, so that it caches built files.

Or you can use image from a registry gitlab-registry.cern.ch/lhcb/allen:latest
```bash
mkdir build
docker run -it --gpus '"device=1"' -v /app/build:$(pwd)/build lhcb/allen:latest /bin/bash
```
Inside a container run
```bash
scl enable devtoolset-8 -- bash
cmake -DCMAKE_BUILD_TYPE=Release .. &&  make -j 22
```

> Note: Files inside the build folder would belong to the root user.
