#pragma once

#include "ArgumentManager.cuh"
#include "Configuration.cuh"
#include <functional>
#include <tuple>
#include <utility>

#include "CheckerInvoker.h"
#include "Logger.h"
#include "RuntimeOptions.h"
#include "Constants.cuh"
#include "HostBuffers.cuh"

/**
 * @brief      A Handler that encapsulates a host function.
 *             set_arguments allows to set up the arguments of the function.
 *             invokes calls it.
 */
template<typename R, typename... T>
struct HostFunction {
private:
  std::function<R(T...)> fn;

public:
  HostFunction(std::function<R(T...)> param_function) : fn(param_function) {}

  auto invoke(T... arguments) const
  {
    return fn(arguments...);
  }

  auto operator()(T... arguments) const
  {
    return fn(arguments...);
  }
};

/**
 * @brief      A helper to make Handlers without needing
 *             to specify its function type (ie. "host_function(function)").
 */
template<typename R, typename... T>
static HostFunction<R, T...> host_function(R(f)(T...))
{
  return HostFunction<R, T...> {f};
}
