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
  struct EXPOSED_TYPE_NAME : public Allen::Algorithm {                  \
    constexpr static auto name {#EXPOSED_TYPE_NAME};                                                                \
    using Arguments = DEPENDENCIES;                                                                                 \
    using arguments_t = ArgumentRefManager<Arguments>;                                                              \
    decltype(make_handler(name, FUNCTION)) handler {name, FUNCTION};                                                \
    template<typename T>                                                                                            \
    T get_property_value(std::string property_name) const                                                           \
    {                                                                                                               \
      T holder;                                                                                                     \
      auto prop = dynamic_cast<Allen::Property<T> const*>(get_prop(property_name));                                        \
      if (prop)                                                                                                     \
        holder = prop->get_value();                                                                                 \
      else                                                                                                          \
        warning_cout << "property " << property_name << " not found" << std::endl;                                  \
      return holder;                                                                                                \
    }                                                                                                               \
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
    void invoke() { handler.invoke(); }                                                                             \
                                                                                                                    \
  private:                                                                                                          \
    Allen::CPUProperty<std::array<int, 3>> m_block_dim {this, "block_dim", {32, 1, 1}, "block dimensions"}; \
    Allen::CPUProperty<std::array<int, 3>> m_grid_dim {this, "grid_dim", {1, 1, 1}, "grid dimensions"}; \
    __VA_ARGS__                                                                                                     \
  };

/**
 * @brief      Invokes a function specified by its function and arguments.
 *
 * @param[in]  function            The function.
 * @param[in]  num_blocks          Number of blocks of kernel invocation.
 * @param[in]  num_threads         Number of threads of kernel invocation.
 * @param[in]  shared_memory_size  Shared memory size.
 * @param      stream              The stream where the function will be run.
 * @param[in]  arguments           The arguments of the function.
 * @param[in]  I                   Index sequence
 *
 * @return     Return value of the function.
 */
template<class Fn, class Tuple, unsigned long... I>
void invoke_impl(
  Fn&& function,
  const dim3& num_blocks,
  const dim3& num_threads,
  const unsigned shared_memory_size,
  cudaStream_t* stream,
  const Tuple& invoke_arguments,
  std::index_sequence<I...>)
{
#ifdef CPU
  _unused(num_threads);
  _unused(shared_memory_size);
  _unused(stream);

  gridDim = {num_blocks.x, num_blocks.y, num_blocks.z};
  for (unsigned int i = 0; i < num_blocks.x; ++i) {
    for (unsigned int j = 0; j < num_blocks.y; ++j) {
      for (unsigned int k = 0; k < num_blocks.z; ++k) {
        blockIdx = {i, j, k};
        function(std::get<I>(invoke_arguments)...);
      }
    }
  }
#elif defined(HIP)
  hipLaunchKernelGGL(function, num_blocks, num_threads, shared_memory_size, *stream, std::get<I>(invoke_arguments)...);
#else
  function<<<num_blocks, num_threads, shared_memory_size, *stream>>>(std::get<I>(invoke_arguments)...);
#endif
}

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

  void invoke()
  {
    invoke_impl(
      function,
      num_blocks,
      num_threads,
      shared_memory_size,
      stream,
      invoke_arguments,
      std::make_index_sequence<std::tuple_size<std::tuple<T...>>::value>());

    // Check result of kernel call
    cudaCheckKernelCall(cudaPeekAtLastError(), name);
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
