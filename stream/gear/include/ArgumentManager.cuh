/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <tuple>
#include <vector>
#include <cstring>
#include "BackendCommon.h"
#include "Logger.h"
#include "TupleTools.cuh"
#include "Argument.cuh"
#include "BankTypes.h"

/**
 * @brief Helper class to generate arguments based on
 *        the information provided by the base_pointer and offsets
 */
template<typename Tuple>
struct ArgumentManager {
  Tuple arguments_tuple;
  char* device_base_pointer;
  char* host_base_pointer;

  ArgumentManager() = default;

  void set_base_pointers(char* param_device_base_pointer, char* param_host_base_pointer)
  {
    device_base_pointer = param_device_base_pointer;
    host_base_pointer = param_host_base_pointer;
  }

  template<typename T>
  auto data() const
  {
    auto pointer = tuple_ref_by_inheritance<T>(arguments_tuple).offset();
    return reinterpret_cast<typename T::type*>(pointer);
  }

  template<typename T>
  size_t size() const
  {
    return tuple_ref_by_inheritance<T>(arguments_tuple).size();
  }

  template<typename T>
  std::string name() const
  {
    return tuple_ref_by_inheritance<T>(arguments_tuple).name();
  }

  template<typename T>
  typename std::enable_if<std::is_base_of<device_datatype, T>::value>::type set_offset(const unsigned offset)
  {
    tuple_ref_by_inheritance<T>(arguments_tuple).set_offset(device_base_pointer + offset);
  }

  template<typename T>
  typename std::enable_if<std::is_base_of<host_datatype, T>::value>::type set_offset(const unsigned offset)
  {
    tuple_ref_by_inheritance<T>(arguments_tuple).set_offset(host_base_pointer + offset);
  }

  template<typename T>
  void set_size(const size_t size)
  {
    tuple_ref_by_inheritance<T>(arguments_tuple).set_size(size * sizeof(typename T::type));
  }
};

/**
 * @brief Manager of argument references for every handler.
 */
template<typename TupleToReferences, typename ParameterTuple = void, typename ParameterStruct = void>
struct ArgumentRefManager {
  using parameter_tuple_t = ParameterTuple;
  using parameter_struct_t = ParameterStruct;
  using tuple_to_references_t = TupleToReferences;

  TupleToReferences m_arguments;

  ArgumentRefManager(TupleToReferences arguments) : m_arguments(arguments) {}

  template<typename T>
  auto data() const
  {
    auto pointer = std::get<T&>(m_arguments).offset();
    return reinterpret_cast<typename T::type*>(pointer);
  }

  template<typename T>
  auto first() const
  {
    return data<T>()[0];
  }

  template<typename T>
  size_t size() const
  {
    return std::get<T&>(m_arguments).size();
  }

  template<typename T>
  void set_size(const size_t size)
  {
    std::get<T&>(m_arguments).set_size(size * sizeof(typename T::type));
  }

  template<typename T>
  std::string name() const
  {
    return std::get<T&>(m_arguments).name();
  }
};

// Wraps tuple arguments
template<typename Tuple, typename Enabled = void>
struct WrappedTuple;

template<>
struct WrappedTuple<std::tuple<>, void> {
  using t = std::tuple<>;
  using parameter_tuple_t = std::tuple<>;
};

template<typename T, typename... R>
struct WrappedTuple<
  std::tuple<T, R...>,
  typename std::enable_if<
    std::is_base_of<device_datatype, T>::value || std::is_base_of<host_datatype, T>::value>::type> {
  using previous_t = typename WrappedTuple<std::tuple<R...>>::t;
  using t = typename TupleAppendFirst<T&, previous_t>::t;
  using previous_parameter_tuple_t = typename WrappedTuple<std::tuple<R...>>::parameter_tuple_t;
  using parameter_tuple_t = typename TupleAppendFirst<T, previous_parameter_tuple_t>::t;
};

template<typename T, typename... R>
struct WrappedTuple<
  std::tuple<T, R...>,
  typename std::enable_if<
    !std::is_base_of<device_datatype, T>::value && !std::is_base_of<host_datatype, T>::value>::type> {
  using t = typename WrappedTuple<std::tuple<R...>>::t;
  using previous_parameter_tuple_t = typename WrappedTuple<std::tuple<R...>>::parameter_tuple_t;
  using parameter_tuple_t = typename TupleAppendFirst<T, previous_parameter_tuple_t>::t;
};

template<typename T>
struct ParameterTuple {
  using t = typename WrappedTuple<decltype(
    boost::hana::to<boost::hana::ext::std::tuple_tag>(boost::hana::members(std::declval<T>())))>::t;
};

template<typename T>
using ArgumentReferences = ArgumentRefManager<
  typename WrappedTuple<decltype(
    boost::hana::to<boost::hana::ext::std::tuple_tag>(boost::hana::members(std::declval<T>())))>::t,
  typename WrappedTuple<decltype(
    boost::hana::to<boost::hana::ext::std::tuple_tag>(boost::hana::members(std::declval<T>())))>::parameter_tuple_t,
  T>;

// Helpers
template<typename Arg, typename Args>
void set_size(Args arguments, const size_t size)
{
  arguments.template set_size<Arg>(size);
}

template<typename Arg, typename Args>
size_t size(const Args& arguments)
{
  return arguments.template size<Arg>();
}

template<typename Arg, typename Args>
auto data(const Args& arguments)
{
  return Arg {arguments.template data<Arg>()};
}

template<typename Arg, typename Args>
auto first(const Args& arguments)
{
  return arguments.template first<Arg>();
}

template<typename Arg, typename Args, typename T>
void safe_assign_to_host_buffer(T* array, unsigned& size, const Args& arguments, cudaStream_t cuda_stream)
{
  if (arguments.template size<Arg>() > size) {
    size = arguments.template size<Arg>() * 1.2f;
    cudaCheck(cudaFreeHost(array));
    cudaCheck(cudaMallocHost((void**) &array, size));
  }

  cudaCheck(cudaMemcpyAsync(
    array, arguments.template data<Arg>(), arguments.template size<Arg>(), cudaMemcpyDeviceToHost, cuda_stream));
}

// SFINAE for single argument functions, like initialization and print of host / device parameters
template<typename Arg, typename Args, typename Enabled = void>
struct SingleArgumentOverloadResolution;

template<typename Arg, typename Args>
struct SingleArgumentOverloadResolution<
  Arg,
  Args,
  typename std::enable_if<
    std::is_base_of<host_datatype, Arg>::value &&
    (std::is_same<typename Arg::type, bool>::value || std::is_same<typename Arg::type, char>::value ||
     std::is_same<typename Arg::type, unsigned char>::value ||
     std::is_same<typename Arg::type, signed char>::value)>::type> {
  constexpr static void initialize(const Args& arguments, const int value, cudaStream_t)
  {
    std::memset(data<Arg>(arguments), value, size<Arg>(arguments));
  }

  static void print(const Args& arguments)
  {
    const auto array = data<Arg>(arguments);
    for (unsigned i = 0; i < size<Arg>(arguments) / sizeof(typename Arg::type); ++i) {
      info_cout << ((int) array[i]) << ", ";
    }
    info_cout << "\n";
  }
};

template<typename Arg, typename Args>
struct SingleArgumentOverloadResolution<
  Arg,
  Args,
  typename std::enable_if<
    std::is_base_of<host_datatype, Arg>::value &&
    !(std::is_same<typename Arg::type, bool>::value || std::is_same<typename Arg::type, char>::value ||
      std::is_same<typename Arg::type, unsigned char>::value ||
      std::is_same<typename Arg::type, signed char>::value)>::type> {
  constexpr static void initialize(const Args& arguments, const int value, cudaStream_t)
  {
    std::memset(data<Arg>(arguments), value, size<Arg>(arguments));
  }

  static void print(const Args& arguments)
  {
    const auto array = data<Arg>(arguments);
    for (unsigned i = 0; i < size<Arg>(arguments) / sizeof(typename Arg::type); ++i) {
      info_cout << array[i] << ", ";
    }
    info_cout << "\n";
  }
};

template<typename Arg, typename Args>
struct SingleArgumentOverloadResolution<
  Arg,
  Args,
  typename std::enable_if<
    std::is_base_of<device_datatype, Arg>::value &&
    (std::is_same<typename Arg::type, bool>::value || std::is_same<typename Arg::type, char>::value ||
     std::is_same<typename Arg::type, unsigned char>::value ||
     std::is_same<typename Arg::type, signed char>::value)>::type> {
  constexpr static void initialize(const Args& arguments, const int value, cudaStream_t stream)
  {
    cudaCheck(cudaMemsetAsync(data<Arg>(arguments), value, size<Arg>(arguments), stream));
  }

  static void print(const Args& arguments)
  {
    std::vector<char> v(size<Arg>(arguments));
    cudaCheck(cudaMemcpy(v.data(), data<Arg>(arguments), size<Arg>(arguments), cudaMemcpyDeviceToHost));

    for (const auto& i : v) {
      info_cout << ((int) i) << ", ";
    }
    info_cout << "\n";
  }
};

template<typename Arg, typename Args>
struct SingleArgumentOverloadResolution<
  Arg,
  Args,
  typename std::enable_if<
    std::is_base_of<device_datatype, Arg>::value &&
    !(std::is_same<typename Arg::type, bool>::value || std::is_same<typename Arg::type, char>::value ||
      std::is_same<typename Arg::type, unsigned char>::value ||
      std::is_same<typename Arg::type, signed char>::value)>::type> {
  constexpr static void initialize(const Args& arguments, const int value, cudaStream_t stream)
  {
    cudaCheck(cudaMemsetAsync(data<Arg>(arguments), value, size<Arg>(arguments), stream));
  }

  static void print(const Args& arguments)
  {
    std::vector<typename Arg::type> v(size<Arg>(arguments) / sizeof(typename Arg::type));
    cudaCheck(cudaMemcpy(v.data(), data<Arg>(arguments), size<Arg>(arguments), cudaMemcpyDeviceToHost));

    for (const auto& i : v) {
      info_cout << i << ", ";
    }
    info_cout << "\n";
  }
};

// SFINAE for double argument functions, like copying
template<typename A, typename B, typename Args, typename Enabled = void>
struct DoubleArgumentOverloadResolution;

// Host to host
template<typename A, typename B, typename Args>
struct DoubleArgumentOverloadResolution<
  A,
  B,
  Args,
  typename std::conditional<
    std::is_base_of<host_datatype, A>::value,
    typename std::enable_if<std::is_base_of<host_datatype, B>::value>::type,
    typename std::enable_if<false>>::type> {
  constexpr static void copy(const Args& arguments, cudaStream_t)
  {
    assert(size<A>(arguments) >= size<B>(arguments));
    std::memcpy(data<A>(arguments), data<B>(arguments), size<B>(arguments));
  }

  constexpr static void copy(const Args& arguments, const size_t count, cudaStream_t)
  {
    assert(size<A>(arguments) >= count && size<B>(arguments) >= count);
    std::memcpy(data<A>(arguments), data<B>(arguments), count);
  }
};

// Device to host
template<typename A, typename B, typename Args>
struct DoubleArgumentOverloadResolution<
  A,
  B,
  Args,
  typename std::conditional<
    std::is_base_of<host_datatype, A>::value,
    typename std::enable_if<std::is_base_of<device_datatype, B>::value>::type,
    typename std::enable_if<false>>::type> {
  constexpr static void copy(const Args& arguments, cudaStream_t cuda_stream)
  {
    assert(size<A>(arguments) >= size<B>(arguments));
    cudaCheck(
      cudaMemcpyAsync(data<A>(arguments), data<B>(arguments), size<B>(arguments), cudaMemcpyDeviceToHost, cuda_stream));
  }

  constexpr static void copy(const Args& arguments, const size_t count, cudaStream_t cuda_stream)
  {
    assert(size<A>(arguments) >= count && size<B>(arguments) >= count);
    cudaCheck(cudaMemcpyAsync(data<A>(arguments), data<B>(arguments), count, cudaMemcpyDeviceToHost, cuda_stream));
  }
};

// Host to device
template<typename A, typename B, typename Args>
struct DoubleArgumentOverloadResolution<
  A,
  B,
  Args,
  typename std::conditional<
    std::is_base_of<device_datatype, A>::value,
    typename std::enable_if<std::is_base_of<host_datatype, B>::value>::type,
    typename std::enable_if<false>>::type> {
  constexpr static void copy(const Args& arguments, cudaStream_t cuda_stream)
  {
    assert(size<A>(arguments) >= size<B>(arguments));
    cudaCheck(
      cudaMemcpyAsync(data<A>(arguments), data<B>(arguments), size<B>(arguments), cudaMemcpyHostToDevice, cuda_stream));
  }

  constexpr static void copy(const Args& arguments, const size_t count, cudaStream_t cuda_stream)
  {
    assert(size<A>(arguments) >= count && size<B>(arguments) >= count);
    cudaCheck(cudaMemcpyAsync(data<A>(arguments), data<B>(arguments), count, cudaMemcpyHostToDevice, cuda_stream));
  }
};

// Device to device
template<typename A, typename B, typename Args>
struct DoubleArgumentOverloadResolution<
  A,
  B,
  Args,
  typename std::conditional<
    std::is_base_of<device_datatype, A>::value,
    typename std::enable_if<std::is_base_of<device_datatype, B>::value>::type,
    typename std::enable_if<false>>::type> {
  constexpr static void copy(const Args& arguments, cudaStream_t cuda_stream)
  {
    assert(size<A>(arguments) >= size<B>(arguments));
    cudaCheck(cudaMemcpyAsync(
      data<A>(arguments), data<B>(arguments), size<B>(arguments), cudaMemcpyDeviceToDevice, cuda_stream));
  }

  constexpr static void copy(const Args& arguments, const size_t count, cudaStream_t cuda_stream)
  {
    assert(size<A>(arguments) >= count && size<B>(arguments) >= count);
    cudaCheck(cudaMemcpyAsync(data<A>(arguments), data<B>(arguments), count, cudaMemcpyDeviceToDevice, cuda_stream));
  }
};

/**
 * @brief Initializes a datatype with the value specified.
 *        Can be used to either initialize values on the host or on the device.
 * @details On the host, this resolves to a std::memset.
 *          On the device, this resolves to a cudaMemsetAsync. No synchronization
 *          is performed after the initialization.
 */
template<typename Arg, typename Args>
void initialize(const Args& arguments, const int value, cudaStream_t stream = 0)
{
  SingleArgumentOverloadResolution<Arg, Args>::initialize(arguments, value, stream);
}

/**
 * @brief Prints the value of an argument.
 * @details On the host, a mere loop and a print statement is done.
 *          On the device, a cudaMemcpy is used to first copy the data onto a std::vector.
 *          Note that as a consequence of this, printing device variables results in a
 *          considerable slowdown.
 */
template<typename Arg, typename Args>
void print(const Args& arguments)
{
  SingleArgumentOverloadResolution<Arg, Args>::print(arguments);
}

/**
 * @brief Copies B into A.
 * @details A and B may be host or device arguments (the four options).
 */
template<typename A, typename B, typename Args>
void copy(const Args& arguments, cudaStream_t stream = 0)
{
  DoubleArgumentOverloadResolution<A, B, Args>::copy(arguments, stream);
}

/**
 * @brief Copies count bytes of B into A.
 * @details A and B may be host or device arguments (the four options).
 */
template<typename A, typename B, typename Args>
void copy(const Args& arguments, const size_t count, cudaStream_t stream = 0)
{
  DoubleArgumentOverloadResolution<A, B, Args>::copy(arguments, count, stream);
}

/**
 * @brief Transfer data to the device, populating raw banks and offsets.
 */
template<class DATA_ARG, class OFFSET_ARG, class ARGUMENTS>
void data_to_device(ARGUMENTS const& args, BanksAndOffsets const& bno, cudaStream_t& cuda_stream)
{
  auto offset = args.template data<DATA_ARG>();
  for (gsl::span<char const> data_span : std::get<0>(bno)) {
    cudaCheck(cudaMemcpyAsync(offset, data_span.data(), data_span.size_bytes(), cudaMemcpyHostToDevice, cuda_stream));
    offset += data_span.size_bytes();
  }

  cudaCheck(cudaMemcpyAsync(
    args.template data<OFFSET_ARG>(),
    std::get<2>(bno).data(),
    std::get<2>(bno).size_bytes(),
    cudaMemcpyHostToDevice,
    cuda_stream));
}
