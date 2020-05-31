#pragma once

#include <tuple>
#include "BankTypes.h"

/**
 * @brief Sets the size of a container to the specified size.
 */
template<typename Arg, typename Args>
void set_size(Args arguments, const size_t size)
{
  arguments.template set_size<Arg>(size);
}

/**
 * @brief Reduces the size of the container.
 * @details Reducing the size can be done after the data has
 *          been allocated (such as in the operator() of an 
 *          algorithm). It reduces the exposed size of an
 *          argument.
 *          
 *          Note however that this does not impact the amount
 *          of allocated memory of the container, which remains unchanged.
 */
template<typename Arg, typename Args>
void reduce_size(const Args& arguments, const size_t size)
{
  assert(size <= arguments.template size<Arg>());
  const_cast<Args&>(arguments).template set_size<Arg>(size);
}


/**
 * @brief Returns the size of a container (length * sizeof(T)).
 */
template<typename Arg, typename Args>
size_t size(const Args& arguments)
{
  return arguments.template size<Arg>();
}

/**
 * @brief Returns the length of a container.
 */
template<typename Arg, typename Args>
size_t length(const Args& arguments)
{
  return arguments.template size<Arg>() / Arg::type;
}

/**
 * @brief Returns a pointer to the container with the container type.
 */
template<typename Arg, typename Args>
auto data(const Args& arguments)
{
  return Arg {arguments.template data<Arg>()};
}

/**
 * @brief Returns the first element in the container.
 */
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

  constexpr static void
  copy(const Args& arguments, const size_t count, cudaStream_t, const size_t offset_a, const size_t offset_b)
  {
    assert(
      (size<A>(arguments) - offset_a * sizeof(typename A::type)) >= count &&
      (size<B>(arguments) - offset_b * sizeof(typename B::type)) >= count);
    std::memcpy(data<A>(arguments) + offset_a, data<B>(arguments) + offset_b, count);
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

  constexpr static void copy(
    const Args& arguments,
    const size_t count,
    cudaStream_t cuda_stream,
    const size_t offset_a,
    const size_t offset_b)
  {
    assert(
      (size<A>(arguments) - offset_a * sizeof(typename A::type)) >= count &&
      (size<B>(arguments) - offset_b * sizeof(typename B::type)) >= count);
    cudaCheck(cudaMemcpyAsync(
      data<A>(arguments) + offset_a, data<B>(arguments) + offset_b, count, cudaMemcpyDeviceToHost, cuda_stream));
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

  constexpr static void copy(
    const Args& arguments,
    const size_t count,
    cudaStream_t cuda_stream,
    const size_t offset_a,
    const size_t offset_b)
  {
    assert(
      (size<A>(arguments) - offset_a * sizeof(typename A::type)) >= count &&
      (size<B>(arguments) - offset_b * sizeof(typename B::type)) >= count);
    cudaCheck(cudaMemcpyAsync(
      data<A>(arguments) + offset_a, data<B>(arguments) + offset_b, count, cudaMemcpyHostToDevice, cuda_stream));
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

  constexpr static void copy(
    const Args& arguments,
    const size_t count,
    cudaStream_t cuda_stream,
    const size_t offset_a,
    const size_t offset_b)
  {
    assert(
      (size<A>(arguments) - offset_a * sizeof(typename A::type)) >= count &&
      (size<B>(arguments) - offset_b * sizeof(typename B::type)) >= count);
    cudaCheck(cudaMemcpyAsync(
      data<A>(arguments) + offset_a, data<B>(arguments) + offset_b, count, cudaMemcpyDeviceToDevice, cuda_stream));
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
void initialize(const Args& arguments, const int value, cudaStream_t stream)
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
 * @details A and B may be host or device arguments.
 */
template<typename A, typename B, typename Args>
void copy(const Args& arguments, cudaStream_t stream)
{
  DoubleArgumentOverloadResolution<A, B, Args>::copy(arguments, stream);
}

/**
 * @brief Copies count bytes of B into A.
 * @details A and B may be host or device arguments.
 */
template<typename A, typename B, typename Args>
void copy(
  const Args& arguments,
  const size_t count,
  cudaStream_t stream,
  const size_t offset_a = 0,
  const size_t offset_b = 0)
{
  DoubleArgumentOverloadResolution<A, B, Args>::copy(arguments, count, stream, offset_a, offset_b);
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
