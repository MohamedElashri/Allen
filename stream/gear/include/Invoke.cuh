#include "CudaCommon.h"

/**
 * @brief      Invokes a function specified by its function and arguments.
 *
 * @param[in]  function            The function.
 * @param[in]  num_blocks          Number of blocks of kernel invocation.
 * @param[in]  num_threads         Number of threads of kernel invocation.
 * @param[in]  shared_memory_size  Shared memory size.
 * @param      stream              The stream where the function will be run.
 * @param[in]  arguments           The arguments of the function.
 * @param[in]  I                   Index sequence
 *
 * @return     Return value of the function.
 */
template<class Fn, class Tuple, unsigned long... I>
void invoke_impl(
  Fn&& function,
  const dim3& num_blocks,
  const dim3& num_threads,
  cudaStream_t* stream,
  const Tuple& invoke_arguments,
  std::index_sequence<I...>)
{
#ifdef CPU
  _unused(num_threads);
  _unused(stream);

  gridDim = {num_blocks.x, num_blocks.y, num_blocks.z};
  for (unsigned int i = 0; i < num_blocks.x; ++i) {
    for (unsigned int j = 0; j < num_blocks.y; ++j) {
      for (unsigned int k = 0; k < num_blocks.z; ++k) {
        blockIdx = {i, j, k};
        function(std::get<I>(invoke_arguments)...);
      }
    }
  }
#elif defined(HIP)
  hipLaunchKernelGGL(function, num_blocks, num_threads, *stream, std::get<I>(invoke_arguments)...);
#else
  function<<<num_blocks, num_threads, *stream>>>(std::get<I>(invoke_arguments)...);
#endif
}

template<class Handler>
void invoke_helper(const Handler& handler) {
  invoke_impl(
    handler.function,
    handler.num_blocks,
    handler.num_threads,
    handler.stream,
    handler.invoke_arguments,
    std::make_index_sequence<std::tuple_size<decltype(handler.invoke_arguments)>::value>());

  // Check result of kernel call
  cudaCheckKernelCall(cudaPeekAtLastError());
}