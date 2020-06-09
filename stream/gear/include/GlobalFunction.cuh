#pragma once

#include "ArgumentManager.cuh"
#include "Property.cuh"
#include "HostFunction.cuh"
#include "Invoke.cuh"
#include "CudaCommon.h"
#include <functional>
#include <utility>
#include <tuple>

template<typename P, typename R, typename... T>
struct GlobalFunctionImpl {
private:
  P m_class_ptr;
  R (*m_fn)(T...);
  dim3 m_num_blocks;
  dim3 m_num_threads;
  cudaStream_t m_stream;

public:
  GlobalFunctionImpl(
    P class_ptr,
    R (*param_function)(T...),
    const dim3& num_blocks,
    const dim3& num_threads,
    cudaStream_t stream) :
    m_class_ptr(class_ptr),
    m_fn(param_function), m_num_blocks(num_blocks), m_num_threads(num_threads), m_stream(stream)
  {}

  template<typename... S>
  void operator()(S&&... arguments) const
  {
    const auto invoke_arguments =
      std::tuple<T...> {TransformParameter<S>::template transform<P>(std::forward<S>(arguments), m_class_ptr)...};

    // Delegate function invocation
    invoke_impl(
      m_fn, m_num_blocks, m_num_threads, m_stream, invoke_arguments, std::make_index_sequence<sizeof...(T)>());

    // Check result of kernel call
    cudaCheckKernelCall(cudaPeekAtLastError());
  }
};

/**
 * @brief A class that encapsulates a CUDA function.
 */
template<typename P, typename R, typename... T>
struct GlobalFunction {
private:
  P m_class_ptr;
  R (*m_fn)(T...);

public:
  // Constructor. Encapsulates a CUDA function.
  GlobalFunction(P class_ptr, R (*param_function)(T...)) : m_class_ptr(class_ptr), m_fn(param_function) {}

  // The syntax of operator() resembles the CUDA syntax:
  //  foo(num_blocks, num_threads, cuda_stream)(arguments...)
  auto operator()(const dim3& num_blocks, const dim3& num_threads, cudaStream_t stream) const
  {
    return GlobalFunctionImpl<P, R, T...> {m_class_ptr, m_fn, num_blocks, num_threads, stream};
  }
};
