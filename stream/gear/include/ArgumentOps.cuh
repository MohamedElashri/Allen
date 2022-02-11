/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include <tuple>
#include <gsl/gsl>
#include "BankTypes.h"
#include "BackendCommon.h"
#include "AllenTypeTraits.h"
#include "PinnedVector.h"
#include "ArgumentManager.cuh"

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
  arguments.template reduce_size<Arg>(size);
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
 * @brief Returns a pointer to the container with the container type.
 */
template<typename Arg, typename Args>
auto* data(const Args& arguments)
{
  return arguments.template pointer<Arg>();
}

/**
 * @brief Returns the first element in the container.
 */
template<typename Arg, typename Args>
auto first(const Args& arguments)
{
  return arguments.template first<Arg>();
}

/**
 * @brief Gets the name of a container.
 */
template<typename Arg, typename Args>
std::string name(Args arguments)
{
  return arguments.template name<Arg>();
}

/**
 * @brief Fetches an aggregate value.
 */
template<typename Arg, typename Args>
auto input_aggregate(const Args& arguments)
{
  return arguments.template input_aggregate<Arg>();
}

template<typename Arg, typename Args, typename T>
void safe_assign_to_host_buffer(T* array, unsigned& array_size, const Args& arguments, const Allen::Context& context)
{
  if (size<Arg>(arguments) * sizeof(typename Arg::type) > array_size) {
    array_size = size<Arg>(arguments) * sizeof(typename Arg::type);
    Allen::free_host(array);
    Allen::malloc_host((void**) &array, array_size);
  }

  Allen::memcpy_async(
    array, data<Arg>(arguments), size<Arg>(arguments) * sizeof(typename Arg::type), Allen::memcpyDeviceToHost, context);
}

template<typename Arg, typename Args, typename T>
void safe_assign_to_host_buffer(gsl::span<T>& span, const Args& arguments, const Allen::Context& context)
{
  static_assert(sizeof(typename Arg::type) == sizeof(T));

  // Ensure span is big enough
  if (size<Arg>(arguments) >= span.size()) {
    // Deallocate previously allocated data, if any
    if (span.data() != nullptr) {
      Allen::free_host(span.data());
    }

    // Pinned allocation of new buffer of required size
    T* buffer_pointer;
    const auto buffer_size = size<Arg>(arguments);
    Allen::malloc_host((void**) &buffer_pointer, buffer_size * sizeof(typename Arg::type));

    // Update the span
    span = {buffer_pointer, buffer_size};
  }

  // Actual copy to the span
  Allen::memcpy_async(
    span.data(),
    data<Arg>(arguments),
    size<Arg>(arguments) * sizeof(typename Arg::type),
    Allen::memcpyDeviceToHost,
    context);
}

/**
 * @brief Transfer data to a resizable host buffer, requires a std::vector.
 */
template<typename Arg, typename Args, typename T>
void safe_assign_to_host_buffer(std::vector<T>& container, const Args& arguments)
{
  if (container.size() < size<Arg>(arguments)) {
    container.resize(size<Arg>(arguments));
  }
  Allen::memcpy(
    container.data(),
    data<Arg>(arguments),
    size<Arg>(arguments) * sizeof(typename Arg::type),
    Allen::memcpyDeviceToHost);
}

template<typename Arg, typename Args, typename T>
void assign_to_host_buffer(T* array, const Args& arguments, const Allen::Context& context)
{
  Allen::memcpy_async(
    array, data<Arg>(arguments), size<Arg>(arguments) * sizeof(typename Arg::type), Allen::memcpyDeviceToHost, context);
}

namespace Allen {
  /**
   * @brief  Base implementation. Copy of two spans with an Allen context and a kind.
   * @detail Uses implementation of backend. An exception is the copy from host to host,
   *         which is done using a std::memcpy instead.
   */
  template<typename T, typename S>
  void copy_async(
    gsl::span<T> container_a,
    gsl::span<S> container_b,
    const Allen::Context& context,
    const Allen::memcpy_kind kind,
    const size_t count = 0,
    const size_t offset_a = 0,
    const size_t offset_b = 0)
  {
    const auto elements_to_copy = count == 0 ? container_b.size() : count;

    static_assert(sizeof(T) == sizeof(S));
    assert((container_a.size() - offset_a) >= elements_to_copy && (container_b.size() - offset_b) >= elements_to_copy);

    if (kind == memcpyHostToHost) {
      std::memcpy(
        static_cast<void*>(container_a.data() + offset_a),
        static_cast<void*>(container_b.data() + offset_b),
        elements_to_copy * sizeof(T));
    }
    else {
      Allen::memcpy_async(
        container_a.data() + offset_a, container_b.data() + offset_b, elements_to_copy * sizeof(T), kind, context);
    }
  }

  /**
   * @brief Copies count bytes of B into A using asynchronous copy.
   * @details A and B may be host or device arguments.
   */
  template<typename A, typename B, typename Args>
  void copy_async(
    const Args& arguments,
    const Allen::Context& context,
    const size_t count = 0,
    const size_t offset_a = 0,
    const size_t offset_b = 0)
  {
    static_assert(sizeof(typename A::type) == sizeof(typename B::type));

    const auto elements_to_copy = count == 0 ? size<B>(arguments) : count;
    const Allen::memcpy_kind kind = []() {
      if constexpr (std::is_base_of_v<host_datatype, A> && std::is_base_of_v<host_datatype, B>)
        return Allen::memcpyHostToHost;
      else if constexpr (std::is_base_of_v<host_datatype, A> && std::is_base_of_v<device_datatype, B>)
        return Allen::memcpyHostToDevice;
      else if constexpr (std::is_base_of_v<device_datatype, A> && std::is_base_of_v<host_datatype, B>)
        return Allen::memcpyDeviceToHost;
      else
        return Allen::memcpyDeviceToDevice;
    }();

    Allen::copy_async(
      gsl::span {data<A>(arguments), size<A>(arguments)},
      gsl::span {data<B>(arguments), size<B>(arguments)},
      context,
      kind,
      elements_to_copy,
      offset_a,
      offset_b);
  }

  /**
   * @brief Synchronous copy of container_b into container_a.
   */
  template<typename T, typename S>
  void copy(
    gsl::span<T> container_a,
    gsl::span<S> container_b,
    const Allen::Context& context,
    const Allen::memcpy_kind kind,
    const size_t count = 0,
    const size_t offset_a = 0,
    const size_t offset_b = 0)
  {
    copy_async(container_a, container_b, context, kind, count, offset_a, offset_b);
    if (kind != memcpyHostToHost) {
      synchronize(context);
    }
  }

  /**
   * @brief Synchronous copy of B into A.
   */
  template<typename A, typename B, typename Args>
  void copy(
    const Args& arguments,
    const Allen::Context& context,
    const size_t count = 0,
    const size_t offset_a = 0,
    const size_t offset_b = 0)
  {
    copy_async<A, B, Args>(arguments, context, count, offset_a, offset_b);
    if constexpr (!std::is_base_of_v<host_datatype, A> || !std::is_base_of_v<host_datatype, B>) {
      synchronize(context);
    }
  }

  namespace aggregate {
    /**
     * @brief Stores contents of aggregate contiguously into container.
     */
    template<typename A, typename B, typename Args>
    void store_contiguous_async(const Args& arguments, const Allen::Context& context)
    {
      auto container = gsl::span {data<A>(arguments), size<A>(arguments)};
      auto aggregate = input_aggregate<B>(arguments);

      const Allen::memcpy_kind kind = []() {
        if constexpr (std::is_base_of_v<host_datatype, A> && std::is_base_of_v<host_datatype, B>)
          return Allen::memcpyHostToHost;
        else if constexpr (std::is_base_of_v<host_datatype, A> && std::is_base_of_v<device_datatype, B>)
          return Allen::memcpyHostToDevice;
        else if constexpr (std::is_base_of_v<device_datatype, A> && std::is_base_of_v<host_datatype, B>)
          return Allen::memcpyDeviceToHost;
        else
          return Allen::memcpyDeviceToDevice;
      }();

      unsigned container_offset = 0;
      for (size_t i = 0; i < aggregate.size_of_aggregate(); ++i) {
        Allen::copy_async(container, aggregate.span(i), context, kind, aggregate.size(i), container_offset);
        container_offset += aggregate.size(i);
      }
    }
  } // namespace aggregate
} // namespace Allen

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
  constexpr static void initialize(const Args& arguments, const int value, const Allen::Context&)
  {
    std::memset(data<Arg>(arguments), value, size<Arg>(arguments) * sizeof(typename Arg::type));
  }

  static void print(const Args& arguments)
  {
    const auto array = data<Arg>(arguments);

    info_cout << name<Arg>(arguments) << ": ";
    for (unsigned i = 0; i < size<Arg>(arguments); ++i) {
      info_cout << ((int) array[i]) << ", ";
    }
    info_cout << "\n";
  }
};

template<typename Arg, typename Args>
struct SingleArgumentOverloadResolution<
  Arg,
  Args,
  std::enable_if_t<
    std::is_base_of_v<host_datatype, Arg> &&
    !(std::is_same_v<typename Arg::type, bool> || std::is_same_v<typename Arg::type, char> ||
      std::is_same_v<typename Arg::type, uint8_t> || std::is_same_v<typename Arg::type, int8_t>)>> {
  constexpr static void initialize(const Args& arguments, const int value, const Allen::Context&)
  {
    std::memset(data<Arg>(arguments), value, size<Arg>(arguments) * sizeof(typename Arg::type));
  }

  /**
   * @brief Asynchronous make_vector.
   */
  static auto make_vector(const Args& arguments, const Allen::Context& context)
  {
    Allen::pinned_vector<Allen::bool_as_char_t<typename Arg::type>> v(size<Arg>(arguments));
    Allen::memcpy_async(
      v.data(),
      data<Arg>(arguments),
      size<Arg>(arguments) * sizeof(typename Arg::type),
      Allen::memcpyHostToHost,
      context);
    return v;
  }

  /**
   * @brief Synchronous make_vector.
   */
  static auto make_vector(const Args& arguments)
  {
    Allen::pinned_vector<Allen::bool_as_char_t<typename Arg::type>> v(size<Arg>(arguments));
    Allen::memcpy(
      v.data(), data<Arg>(arguments), size<Arg>(arguments) * sizeof(typename Arg::type), Allen::memcpyHostToHost);
    return v;
  }

  static void print(const Args& arguments)
  {
    const auto array = data<Arg>(arguments);

    info_cout << name<Arg>(arguments) << ": ";
    for (unsigned i = 0; i < size<Arg>(arguments); ++i) {
      info_cout << array[i] << ", ";
    }
    info_cout << "\n";
  }
};

template<typename Arg, typename Args>
struct SingleArgumentOverloadResolution<Arg, Args, std::enable_if_t<std::is_base_of_v<device_datatype, Arg>>> {
  constexpr static void initialize(const Args& arguments, const int value, const Allen::Context& context)
  {
    Allen::memset_async(data<Arg>(arguments), value, size<Arg>(arguments) * sizeof(typename Arg::type), context);
  }

  /**
   * @brief Asynchronous make_vector.
   */
  static auto make_vector(const Args& arguments, const Allen::Context& context)
  {
    Allen::pinned_vector<Allen::bool_as_char_t<typename Arg::type>> v(size<Arg>(arguments));
    Allen::memcpy_async(
      v.data(),
      data<Arg>(arguments),
      size<Arg>(arguments) * sizeof(typename Arg::type),
      Allen::memcpyDeviceToHost,
      context);
    return v;
  }

  /**
   * @brief Synchronous make_vector.
   */
  static auto make_vector(const Args& arguments)
  {
    Allen::pinned_vector<Allen::bool_as_char_t<typename Arg::type>> v(size<Arg>(arguments));
    Allen::memcpy(
      v.data(), data<Arg>(arguments), size<Arg>(arguments) * sizeof(typename Arg::type), Allen::memcpyDeviceToHost);
    return v;
  }

  static void print(const Args& arguments)
  {
    std::vector<Allen::bool_as_char_t<typename Arg::type>> v(size<Arg>(arguments));
    Allen::memcpy(
      v.data(), data<Arg>(arguments), size<Arg>(arguments) * sizeof(typename Arg::type), Allen::memcpyDeviceToHost);

    info_cout << name<Arg>(arguments) << ": ";
    for (const auto& i : v) {
      if constexpr (
        std::is_same_v<typename Arg::type, bool> || std::is_same_v<typename Arg::type, char> ||
        std::is_same_v<typename Arg::type, unsigned char> || std::is_same_v<typename Arg::type, signed char>) {
        info_cout << static_cast<int>(i) << ", ";
      }
      else {
        info_cout << i << ", ";
      }
    }
    info_cout << "\n";
  }
};

/**
 * @brief Initializes a datatype with the value specified.
 *        Can be used to either initialize values on the host or on the device.
 * @details On the host, this resolves to a std::memset.
 *          On the device, this resolves to a Allen::memset_async. No synchronization
 *          is performed after the initialization.
 */
template<typename Arg, typename Args>
void initialize(const Args& arguments, const int value, const Allen::Context& context)
{
  SingleArgumentOverloadResolution<Arg, Args>::initialize(arguments, value, context);
}

/**
 * @brief Prints the value of an argument.
 * @details On the host, a mere loop and a print statement is done.
 *          On the device, a Allen::memcpy is used to first copy the data onto a std::vector.
 *          Note that as a consequence of this, printing device variables results in a
 *          considerable slowdown.
 */
template<typename Arg, typename Args>
void print(const Args& arguments)
{
  SingleArgumentOverloadResolution<Arg, Args>::print(arguments);
}

/**
 * @brief Transfer data to the device, populating raw banks and offsets.
 */
template<class DATA_ARG, class OFFSET_ARG, class ARGUMENTS>
void data_to_device(ARGUMENTS const& args, BanksAndOffsets const& bno, const Allen::Context& context)
{
  auto offset = data<DATA_ARG>(args);
  for (gsl::span<char const> data_span : std::get<0>(bno)) {
    Allen::memcpy_async(offset, data_span.data(), data_span.size_bytes(), Allen::memcpyHostToDevice, context);
    offset += data_span.size_bytes();
  }

  Allen::memcpy_async(
    data<OFFSET_ARG>(args), std::get<2>(bno).data(), std::get<2>(bno).size_bytes(), Allen::memcpyHostToDevice, context);
}

/**
 * @brief Makes a std::vector out of an Allen container.
 * @details The copy function here is asynchronous. The only small caveat of this
 *          function is the requirement to dynamically allocate a buffer on the host.
 */
template<typename Arg, typename Args>
auto make_vector(const Args& arguments, const Allen::Context& context)
{
  return SingleArgumentOverloadResolution<Arg, Args>::make_vector(arguments, context);
}

/**
 * @brief Makes a std::vector out of an Allen container.
 * @details This copy mechanism to create a std::vector is blocking and synchronous.
 *          This function should only be used where the performance of the application
 *          is irrelevant.
 */
template<typename Arg, typename Args>
auto make_vector(const Args& arguments)
{
  return SingleArgumentOverloadResolution<Arg, Args>::make_vector(arguments);
}
