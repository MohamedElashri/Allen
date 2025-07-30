/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
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

namespace Allen::Gear::Function {
  template<typename... S>
  auto make_parameters(
    const dim3& grid_dim,
    const dim3& block_dim,
    const unsigned dynamic_shared_memory_size,
    S&&... arguments)
  {
    return std::make_tuple(TransformParameters<S>::transform(
      std::forward<S>(arguments),
      Allen::KernelInvocationConfiguration {grid_dim, block_dim, dynamic_shared_memory_size})...);
  }
} // namespace Allen::Gear::Function

template<typename Fn>
struct GlobalFunctionImpl {
private:
  const dim3& m_grid_dim;
  const dim3& m_block_dim;
  const Allen::Context& m_context;
  const unsigned m_dynamic_shared_memory_size;
  const Fn& m_fn;

public:
  GlobalFunctionImpl(
    const dim3& grid_dim,
    const dim3& block_dim,
    const Allen::Context& context,
    const unsigned dynamic_shared_memory_size,
    const Fn& fn) :
    m_grid_dim(grid_dim),
    m_block_dim(block_dim), m_context(context), m_dynamic_shared_memory_size(dynamic_shared_memory_size), m_fn(fn)
  {}

  template<typename... S>
  void operator()(S&&... arguments) const
  {
    const auto invoke_arguments =
      Allen::Gear::Function::make_parameters(m_grid_dim, m_block_dim, m_dynamic_shared_memory_size, arguments...);

    invoke_device_function(m_fn, m_grid_dim, m_block_dim, m_context, m_dynamic_shared_memory_size, invoke_arguments);

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
  const Fn& m_fn;

public:
  // Constructor. Encapsulates a CUDA function.
  GlobalFunction(const Fn& fn) : m_fn(fn) {}

  // The syntax of operator() resembles the CUDA syntax:
  //  foo(num_blocks, num_threads, cuda_context)(arguments...)
  auto operator()(
    const dim3& num_blocks,
    const dim3& num_threads,
    const Allen::Context& context,
    const unsigned dynamic_shared_memory_size = 0) const
  {
    return GlobalFunctionImpl<Fn> {num_blocks, num_threads, context, dynamic_shared_memory_size, m_fn};
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
  const Fn& m_fn;

public:
  HostFunction(const Fn& fn) : m_fn(fn) {}

  template<typename... S>
  auto operator()(S&&... arguments) const
  {
    return m_fn(TransformParameters<S>::transform(std::forward<S>(arguments), {})...);
  }
};
