#!/bin/bash

mpirun -host localhost -x UCX_NET_DEVICES=mlx5_0:1 -oversubscribe -bind-to none -mca pml ucx -x UCX_TLS=rc_x hwloc-bind os=mlx5_0 $@ : -host localhost -x UCX_NET_DEVICES=mlx5_1:1 -oversubscribe -bind-to none -mca pml ucx -x UCX_TLS=rc_x hwloc-bind os=mlx5_1 $@
