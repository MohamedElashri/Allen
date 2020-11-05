/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "ArgumentManager.cuh"
#include "Property.cuh"
#include "TransformParameters.cuh"
#include "Invoke.cuh"
#include "BackendCommon.h"
#include <functional>
#include <utility>
#include <tuple>

template<typename Fn, typename P>
struct GlobalFunctionImpl {
private:
  P m_class_ptr;
  const dim3& m_grid_dim;
  const dim3& m_block_dim;
  const Allen::Context& m_context;
  const Fn& m_fn;

public:
  GlobalFunctionImpl(
    P class_ptr,
    const dim3& grid_dim,
    const dim3& block_dim,
    const Allen::Context& context,
    const Fn& fn) :
    m_class_ptr(class_ptr),
    m_grid_dim(grid_dim), m_block_dim(block_dim), m_context(context),
    m_fn(fn)
  {}

  template<typename... S>
  void operator()(S&&... arguments) const
  {
    const auto invoke_arguments =
      std::make_tuple(TransformParameters<S>::template transform<P>(std::forward<S>(arguments), m_class_ptr)...);

    // Delegate function invocation
    invoke_device_function(
      m_fn, m_grid_dim, m_block_dim, m_context, invoke_arguments, std::make_index_sequence<sizeof...(S)>());

    // Check result of kernel call
    Allen::peek_at_last_error();
  }
};

/**
 * @brief A class that encapsulates a CUDA function.
 */
template<typename Fn, typename P>
struct GlobalFunction {
private:
  P m_class_ptr;
  const Fn& m_fn;

public:
  // Constructor. Encapsulates a CUDA function.
  GlobalFunction(P class_ptr, const Fn& fn) :
    m_class_ptr(class_ptr), m_fn(fn)
  {}

  // The syntax of operator() resembles the CUDA syntax:
  //  foo(num_blocks, num_threads, cuda_context)(arguments...)
  auto operator()(const dim3& num_blocks, const dim3& num_threads, const Allen::Context& context) const
  {
    return GlobalFunctionImpl<Fn, P> {m_class_ptr, num_blocks, num_threads, context, m_fn};
  }
};

/**
 * @brief      A Handler that encapsulates a host function.
 *             set_arguments allows to set up the arguments of the function.
 *             invokes calls it.
 */
template<typename P, typename R, typename... T>
struct HostFunction {
private:
  P m_class_ptr;
  std::function<R(T...)> m_fn;

public:
  HostFunction(P class_ptr, std::function<R(T...)> fn) : m_class_ptr(class_ptr), m_fn(fn) {}

  template<typename... S>
  auto operator()(S&&... arguments) const
  {
    return m_fn(TransformParameters<S>::template transform<P>(std::forward<S>(arguments), m_class_ptr)...);
  }
};
