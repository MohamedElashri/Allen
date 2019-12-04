#pragma once

#include "ArgumentManager.cuh"
#include "Configuration.cuh"
#include <functional>
#include <tuple>
#include <utility>

/**
 * @brief      A Handler that encapsulates a CPU function.
 *             set_arguments allows to set up the arguments of the function.
 *             invokes calls it.
 */
template<typename R, typename... T>
struct CpuAlgorithm : public Algorithm {
private:
  std::function<R(T...)> fn;

public:
  CpuAlgorithm(std::function<R(T...)> param_function) : fn(param_function) {}

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
static CpuAlgorithm<R, T...> cpu_algorithm(R(f)(T...))
{
  return CpuAlgorithm<R, T...> {f};
}
