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
 * @brief      A Handler that encapsulates a CPU function.
 *             set_arguments allows to set up the arguments of the function.
 *             invokes calls it.
 */
template<typename R, typename... T>
struct CpuFunction {
private:
  std::function<R(T...)> fn;

public:
  CpuFunction(std::function<R(T...)> param_function) : fn(param_function) {}

  auto invoke(T... arguments) const
  {
    return fn(arguments...);
  }
};

/**
 * @brief      A helper to make Handlers without needing
 *             to specify its function type (ie. "make_cpu_handler(function)").
 */
template<typename R, typename... T>
static CpuFunction<R, T...> cpu_function(R(f)(T...))
{
  return CpuFunction<R, T...> {f};
}
