#pragma once

#include "ArgumentManager.cuh"
#include "Invoke.cuh"
#include <tuple>
#include <utility>
#include <cstdint>
#include <cassert>

/**
 * @brief A class that encapsulates a CUDA function.
 */
template<typename R, typename... T>
struct GlobalFunction {
private:
  // Function
  R (*fn)(T...);

  // Invocation of function with CUDA parameters
  void invoke_fn(const dim3& num_blocks,
    const dim3& num_threads,
    cudaStream_t& stream,
    T... arguments) const
  {
    const auto invoke_arguments = std::tuple<T...> {arguments...};

    // Delegate function invocation
    invoke_impl(
      fn,
      num_blocks,
      num_threads,
      &stream,
      invoke_arguments,
      std::make_index_sequence<sizeof...(T)>());

    // Check result of kernel call
    cudaCheckKernelCall(cudaPeekAtLastError());
  }

public:
  // Constructor. Encapsulates a CUDA function.
  GlobalFunction(R (*param_function)(T...)) : fn(param_function) {}

  // The syntax of operator() resembles the CUDA syntax:
  //  foo(num_blocks, num_threads, cuda_stream)(arguments...)
  auto operator()(const dim3& param_num_blocks,
    const dim3& param_num_threads,
    cudaStream_t& param_stream) const {
    return [&] (T... arguments) {
      invoke_fn(param_num_blocks, param_num_threads, param_stream, arguments...);
    };
  }
};

/**
 * @brief      A helper to make GlobalFunctions without needing
 *             to specify its function type (ie. "global_function(function)").
 */
template<typename R, typename... T>
GlobalFunction<R, T...> global_function(R(f)(T...))
{
  return GlobalFunction<R, T...> {f};
}
