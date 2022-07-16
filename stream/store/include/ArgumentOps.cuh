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
#include "Datatype.cuh"
#include "Logger.h"
#include "AllenBuffer.cuh"

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

    const auto elements_to_copy = count == 0 ? arguments.template size<B>() : count;
    const Allen::memcpy_kind kind = []() {
      if constexpr (
        std::is_base_of_v<Allen::Store::host_datatype, A> && std::is_base_of_v<Allen::Store::host_datatype, B>)
        return Allen::memcpyHostToHost;
      else if constexpr (
        std::is_base_of_v<Allen::Store::host_datatype, A> && std::is_base_of_v<Allen::Store::device_datatype, B>)
        return Allen::memcpyDeviceToHost;
      else if constexpr (
        std::is_base_of_v<Allen::Store::device_datatype, A> && std::is_base_of_v<Allen::Store::host_datatype, B>)
        return Allen::memcpyHostToDevice;
      else
        return Allen::memcpyDeviceToDevice;
    }();

    Allen::copy_async(
      arguments.template get<A>(), arguments.template get<B>(), context, kind, elements_to_copy, offset_a, offset_b);
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
    if constexpr (
      !std::is_base_of_v<Allen::Store::host_datatype, A> || !std::is_base_of_v<Allen::Store::host_datatype, B>) {
      synchronize(context);
    }
  }

  /**
   * @brief Sets count bytes in T using asynchronous memset.
   * @details T may be a host or device argument.
   */
  template<typename T, typename Args>
  void memset_async(
    const Args& arguments,
    const int value,
    const Allen::Context& context,
    const size_t count = 0,
    const size_t offset = 0)
  {
    assert(count == 0 || count <= arguments.template size<T>() - offset);

    const auto s = count == 0 ? arguments.template size<T>() - offset : count;
    if constexpr (std::is_base_of_v<Allen::Store::host_datatype, T>)
      std::memset(arguments.template data<T>() + offset, value, s * sizeof(typename T::type));
    else
      Allen::memset_async(arguments.template data<T>() + offset, value, s * sizeof(typename T::type), context);
  }

  /**
   * @brief Synchronous memset of T.
   */
  template<typename T, typename Args>
  void memset(
    const Args& arguments,
    const int value,
    const Allen::Context& context,
    const size_t count = 0,
    const size_t offset = 0)
  {
    memset_async<T>(arguments, value, context, count, offset);
    if constexpr (!std::is_base_of_v<Allen::Store::host_datatype, T>) {
      synchronize(context);
    }
  }

  /**
   * @brief Transfer data to the device, populating raw banks and offsets.
   */
  template<class DATA_ARG, class OFFSET_ARG, class SIZE_ARG, class TYPES_ARG, class ARGUMENTS>
  void data_to_device(ARGUMENTS const& args, BanksAndOffsets const& bno, const Allen::Context& context)
  {
    auto offset = args.template data<DATA_ARG>();
    for (gsl::span<char const> data_span : bno.fragments) {
      Allen::memcpy_async(offset, data_span.data(), data_span.size_bytes(), Allen::memcpyHostToDevice, context);
      offset += data_span.size_bytes();
    }
    assert(static_cast<size_t>(offset - args.template data<DATA_ARG>()) == bno.fragments_mem_size);

    Allen::memcpy_async(
      args.template data<SIZE_ARG>(), bno.sizes.data(), bno.sizes.size_bytes(), Allen::memcpyHostToDevice, context);

    Allen::memcpy_async(
      args.template data<TYPES_ARG>(), bno.types.data(), bno.types.size_bytes(), Allen::memcpyHostToDevice, context);

    Allen::memcpy_async(
      args.template data<OFFSET_ARG>(),
      bno.offsets.data(),
      bno.offsets.size_bytes(),
      Allen::memcpyHostToDevice,
      context);
  }

  namespace aggregate {
    /**
     * @brief Stores contents of aggregate contiguously into container.
     */
    template<typename A, typename B, typename Args>
    void store_contiguous_async(
      const Args& arguments,
      const Allen::Context& context,
      bool fill_if_empty_container = false,
      int fill_value = 0,
      int fill_count = 1)
    {
      auto container = arguments.template get<A>();
      auto aggregate = arguments.template input_aggregate<B>();

      const Allen::memcpy_kind kind = []() {
        if constexpr (
          std::is_base_of_v<Allen::Store::host_datatype, A> && std::is_base_of_v<Allen::Store::host_datatype, B>)
          return Allen::memcpyHostToHost;
        else if constexpr (
          std::is_base_of_v<Allen::Store::host_datatype, A> && std::is_base_of_v<Allen::Store::device_datatype, B>)
          return Allen::memcpyHostToDevice;
        else if constexpr (
          std::is_base_of_v<Allen::Store::device_datatype, A> && std::is_base_of_v<Allen::Store::host_datatype, B>)
          return Allen::memcpyDeviceToHost;
        else
          return Allen::memcpyDeviceToDevice;
      }();

      unsigned container_offset = 0;
      for (size_t i = 0; i < aggregate.size_of_aggregate(); ++i) {
        if (aggregate.size(i) > 0) {
          Allen::copy_async(container, aggregate.get(i), context, kind, aggregate.size(i), container_offset);
          container_offset += aggregate.size(i);
        }
        else if (fill_if_empty_container) {
          Allen::memset_async<A>(arguments, fill_value, context, fill_count, container_offset);
          container_offset += fill_count;
        }
      }
    }
  } // namespace aggregate

  /**
   * @brief A collection of operations that operate on arguments.
   */
  struct ArgumentOperations {
    /**
     * @brief Sets the size of a container to the specified size.
     */
    template<typename Arg, typename Args>
    static void set_size(Args arguments, const size_t size)
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
    static void reduce_size(const Args& arguments, const size_t size)
    {
      arguments.template reduce_size<Arg>(size);
    }

    /**
     * @brief Returns a span to the container.
     */
    template<typename Arg, typename Args>
    static auto get(const Args& arguments)
    {
      return arguments.template get<Arg>();
    }

    /**
     * @brief Returns the size of a container (length * sizeof(T)).
     */
    template<typename Arg, typename Args>
    static auto size(const Args& arguments)
    {
      return arguments.template size<Arg>();
    }

    /**
     * @brief Returns a pointer to the container with the container type.
     */
    template<typename Arg, typename Args>
    static auto data(const Args& arguments)
    {
      return arguments.template data<Arg>();
    }

    /**
     * @brief Returns the first element in the container.
     */
    template<typename Arg, typename Args>
    static auto first(const Args& arguments)
    {
      return arguments.template first<Arg>();
    }

    /**
     * @brief Gets the name of a container.
     */
    template<typename Arg, typename Args>
    static auto name(Args arguments)
    {
      return arguments.template name<Arg>();
    }

    /**
     * @brief Fetches an aggregate value.
     */
    template<typename Arg, typename Args>
    static auto input_aggregate(const Args& arguments)
    {
      return arguments.template input_aggregate<Arg>();
    }

    template<typename T, typename Args>
    static auto make_host_buffer(const Args& arguments, const size_t size)
    {
      return arguments.template make_buffer<Allen::Store::Scope::Host, T>(size);
    }

    template<typename T, typename Args>
    static auto make_device_buffer(const Args& arguments, const size_t size)
    {
      return arguments.template make_buffer<Allen::Store::Scope::Device, T>(size);
    }

    template<typename Arg, typename Args>
    static auto make_host_buffer(const Args& arguments, const Allen::Context& context)
    {
      auto buffer =
        arguments.template make_buffer<Allen::Store::Scope::Host, typename Arg::type>(arguments.template size<Arg>());

      if constexpr (std::is_base_of_v<Allen::Store::host_datatype, Arg>) {
        Allen::copy(buffer.get(), get<Arg>(arguments), context, Allen::memcpyHostToHost);
      }
      else {
        Allen::copy(buffer.get(), get<Arg>(arguments), context, Allen::memcpyDeviceToHost);
      }

      return buffer;
    }

    template<typename Arg, typename Args>
    static auto make_device_buffer(const Args& arguments, const Allen::Context& context)
    {
      auto buffer =
        arguments.template make_buffer<Allen::Store::Scope::Device, typename Arg::type>(arguments.template size<Arg>());

      if constexpr (std::is_base_of_v<Allen::Store::host_datatype, Arg>) {
        Allen::copy(buffer.get(), get<Arg>(arguments), context, Allen::memcpyHostToDevice);
      }
      else {
        Allen::copy(buffer.get(), get<Arg>(arguments), context, Allen::memcpyDeviceToDevice);
      }

      return buffer;
    }

    /**
     * @brief Prints the value of an argument.
     * @details On the host, a mere loop and a print statement is done.
     *          On the device, a Allen::memcpy is used to first copy the data onto a std::vector.
     *          Note that as a consequence of this, printing device variables results in a
     *          considerable slowdown.
     */
    template<typename Arg, typename Args>
    static void print(const Args& arguments)
    {
      if constexpr (std::is_base_of_v<Allen::Store::host_datatype, Arg>) {
        const auto data = arguments.template get<Arg>();
        info_cout << arguments.template name<Arg>() << ": ";
        for (unsigned i = 0; i < data.size(); ++i) {
          info_cout << ((int) data[i]) << ", ";
        }
        info_cout << "\n";
      }
      else {
        std::vector<Allen::bool_as_char_t<typename Arg::type>> v(arguments.template size<Arg>());
        Allen::memcpy(
          v.data(),
          arguments.template data<Arg>(),
          arguments.template size<Arg>() * sizeof(typename Arg::type),
          Allen::memcpyDeviceToHost);

        info_cout << arguments.template name<Arg>() << ": ";
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
    }
  };
} // namespace Allen
