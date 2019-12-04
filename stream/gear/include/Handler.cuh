#pragma once

#include "ArgumentManager.cuh"
#include "Configuration.cuh"
#include "CudaCommon.h"
#include <tuple>
#include <utility>
#include <string>

/**
 * @brief      Macro for defining algorithms defined by a function name.
 *             A struct is created with name EXPOSED_TYPE_NAME that encapsulates
 *             a Handler of type FUNCTION.
 */
#define ALGORITHM(FUNCTION, EXPOSED_TYPE_NAME, DEPENDENCIES, ...)                                                   \
  struct EXPOSED_TYPE_NAME : public Algorithm {                                                                     \
    constexpr static auto name {#EXPOSED_TYPE_NAME};                                                                \
    using Arguments = DEPENDENCIES;                                                                                 \
    using arguments_t = ArgumentRefManager<Arguments>;                                                              \
    decltype(make_handler(name, FUNCTION)) handler {name, FUNCTION};                                                \
    void set_opts(                                                                                                  \
      const dim3& param_num_blocks,                                                                                 \
      const dim3& param_num_threads,                                                                                \
      cudaStream_t& param_stream,                                                                                   \
      const unsigned param_shared_memory_size = 0)                                                                  \
    {                                                                                                               \
      handler.set_opts(param_num_blocks, param_num_threads, param_stream, param_shared_memory_size);                \
    }                                                                                                               \
    void                                                                                                            \
    set_opts(const dim3& param_num_blocks, cudaStream_t& param_stream, const unsigned param_shared_memory_size = 0) \
    {                                                                                                               \
      dim3 n_threads(m_block_dim.get_value()[0], m_block_dim.get_value()[1], m_block_dim.get_value()[2]);           \
      handler.set_opts(param_num_blocks, n_threads, param_stream, param_shared_memory_size);                        \
    }                                                                                                               \
    void set_opts(cudaStream_t& param_stream, const unsigned param_shared_memory_size = 0)                          \
    {                                                                                                               \
      dim3 n_blocks(m_grid_dim.get_value()[0], m_grid_dim.get_value()[1], m_grid_dim.get_value()[2]);               \
      dim3 n_threads(m_block_dim.get_value()[0], m_block_dim.get_value()[1], m_block_dim.get_value()[2]);           \
      handler.set_opts(n_blocks, n_threads, param_stream, param_shared_memory_size);                                \
    }                                                                                                               \
    template<typename... T>                                                                                         \
    void set_arguments(T... param_arguments)                                                                        \
    {                                                                                                               \
      handler.set_arguments(param_arguments...);                                                                    \
    }                                                                                                               \
    void invoke(); \
                                                                                                                    \
  private:                                                                                                          \
    CPUProperty<std::array<int, 3>> m_block_dim {this, "block_dim", {32, 1, 1}, "block dimensions"};                \
    CPUProperty<std::array<int, 3>> m_grid_dim {this, "grid_dim", {1, 1, 1}, "grid dimensions"};                    \
    __VA_ARGS__                                                                                                     \
  };

/**
 * @brief      A Handler that encapsulates a CUDA function.
 *             It exposes set_opts, to set its CUDA specific function
 *             call parameters (inside the <<< >>>).
 *             set_arguments allows to set up the arguments of the function.
 */
template<typename R, typename... T>
struct Handler {
  std::string name = "";
  dim3 num_blocks, num_threads;
  unsigned shared_memory_size = 0;
  cudaStream_t* stream;

  // Call arguments and function
  std::tuple<T...> invoke_arguments;
  R (*function)(T...);

  Handler(const char* name, R (*param_function)(T...)) : name(name), function(param_function) {}

  void set_arguments(T... param_arguments) { invoke_arguments = std::tuple<T...> {param_arguments...}; }

  void set_opts(
    const dim3& param_num_blocks,
    const dim3& param_num_threads,
    cudaStream_t& param_stream,
    const unsigned param_shared_memory_size = 0)
  {
    num_blocks = param_num_blocks;
    num_threads = param_num_threads;
    stream = &param_stream;
    shared_memory_size = param_shared_memory_size;
  }
};

/**
 * @brief      A helper to make Handlers without needing
 *             to specify its function type (ie. "make_handler(function)").
 */
template<typename R, typename... T>
static Handler<R, T...> make_handler(const char* name, R(f)(T...))
{
  return Handler<R, T...> {name, f};
}
