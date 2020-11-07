/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "ArgumentManager.cuh"
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
  const Fn& m_fn;

public:
  GlobalFunctionImpl(
    const std::map<std::string, Allen::BaseProperty*>& properties,
    const dim3& grid_dim,
    const dim3& block_dim,
    const Allen::Context& context,
    const Fn& fn) :
    m_properties(properties),
    m_grid_dim(grid_dim), m_block_dim(block_dim), m_context(context), m_fn(fn)
  {}

  template<typename... S>
  void operator()(S&&... arguments) const
  {
    const auto invoke_arguments =
      std::make_tuple(TransformParameters<S>::transform(std::forward<S>(arguments), m_properties)...);

    // Delegate function invocation
    invoke_device_function(
      m_fn, m_grid_dim, m_block_dim, m_context, invoke_arguments, std::make_index_sequence<sizeof...(S)>());

    // Check result of kernel call
    Allen::peek_at_last_error();

    // TODO: There is an issue HERE when the invoke_arguments tuple is attempted to be destroyed
    // #16 0x00007ffff75eed58 in std::tuple<track_mva_line::track_mva_line_t, track_mva_line::Parameters, unsigned int, unsigned int>::~tuple() (this=0x7ffd4a389e58)
    // at /cvmfs/sft.cern.ch/lcg/releases/gcc/9.2.0-afc57/x86_64-centos7/lib/gcc/x86_64-pc-linux-gnu/9.2.0/../../../../include/c++/9.2.0/tuple:523
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
  auto operator()(const dim3& num_blocks, const dim3& num_threads, const Allen::Context& context) const
  {
    return GlobalFunctionImpl<Fn> {m_properties, num_blocks, num_threads, context, m_fn};
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
    return m_fn(TransformParameters<S>::transform(std::forward<S>(arguments), m_properties)...);
  }
};
