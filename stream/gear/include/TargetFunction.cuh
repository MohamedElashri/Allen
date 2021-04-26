/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "Property.cuh"
#include "TransformParameters.cuh"
#include "Invoke.cuh"
#include "BackendCommon.h"
#include "BaseTypes.cuh"
#include <functional>
#include <utility>
#include <tuple>

template<typename Fn>
struct GlobalFunctionImpl {
private:
  const std::map<std::string, Allen::BaseProperty*>& m_properties;
  const dim3& m_grid_dim;
  const dim3& m_block_dim;
  const Allen::Context& m_context;
  const unsigned m_dynamic_shared_memory_size;
  const Fn& m_fn;

public:
  GlobalFunctionImpl(
    const std::map<std::string, Allen::BaseProperty*>& properties,
    const dim3& grid_dim,
    const dim3& block_dim,
    const Allen::Context& context,
    const unsigned dynamic_shared_memory_size,
    const Fn& fn) :
    m_properties(properties),
    m_grid_dim(grid_dim), m_block_dim(block_dim), m_context(context),
    m_dynamic_shared_memory_size(dynamic_shared_memory_size), m_fn(fn)
  {}

  template<typename... S>
  void operator()(S&&... arguments) const
  {
    const auto invoke_arguments = std::make_tuple(TransformParameters<S>::transform(
      std::forward<S>(arguments),
      m_properties,
      Allen::KernelInvocationConfiguration {m_grid_dim, m_block_dim, m_dynamic_shared_memory_size})...);

    invoke_device_function(
      m_fn,
      m_grid_dim,
      m_block_dim,
      m_context,
      m_dynamic_shared_memory_size,
      invoke_arguments,
      std::make_index_sequence<sizeof...(S)>());

    // Check result of kernel call
    Allen::peek_at_last_error();
  }
};

/**
 * @brief A class that encapsulates a CUDA function.
 */
template<typename Fn>
struct GlobalFunction {
private:
  const std::map<std::string, Allen::BaseProperty*>& m_properties;
  const Fn& m_fn;

public:
  // Constructor. Encapsulates a CUDA function.
  GlobalFunction(const std::map<std::string, Allen::BaseProperty*>& properties, const Fn& fn) :
    m_properties(properties), m_fn(fn)
  {}

  // The syntax of operator() resembles the CUDA syntax:
  //  foo(num_blocks, num_threads, cuda_context)(arguments...)
  auto operator()(
    const dim3& num_blocks,
    const dim3& num_threads,
    const Allen::Context& context,
    const unsigned dynamic_shared_memory_size = 0) const
  {
    return GlobalFunctionImpl<Fn> {m_properties, num_blocks, num_threads, context, dynamic_shared_memory_size, m_fn};
  }
};

/**
 * @brief      A Handler that encapsulates a host function.
 *             set_arguments allows to set up the arguments of the function.
 *             invokes calls it.
 */
template<typename Fn>
struct HostFunction {
private:
  const std::map<std::string, Allen::BaseProperty*>& m_properties;
  const Fn& m_fn;

public:
  HostFunction(const std::map<std::string, Allen::BaseProperty*>& properties, const Fn& fn) :
    m_properties(properties), m_fn(fn)
  {}

  template<typename... S>
  auto operator()(S&&... arguments) const
  {
    return m_fn(TransformParameters<S>::transform(
      std::forward<S>(arguments), m_properties, Allen::KernelInvocationConfiguration {})...);
  }
};
