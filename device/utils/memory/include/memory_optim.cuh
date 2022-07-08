/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

template<typename T, typename F>
__device__ void shared_or_global(
  unsigned size,
  unsigned max_size,
  T* shared_ptr,
  T* global_base_ptr,
  unsigned* global_count,
  const F& f)
{
  if (size >= max_size) {
    __shared__ int index;
    if (threadIdx.x == 0 && threadIdx.y == 0 && threadIdx.z == 0) index = atomicAdd(global_count, size);
    __syncthreads();
    f(&global_base_ptr[index]);
  }
  else {
    f(shared_ptr);
  }
}
