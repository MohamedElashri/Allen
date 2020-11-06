/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <list>
#include <algorithm>
#include "Common.h"
#include "Logger.h"

struct MemoryManager {
  size_t max_available_memory = (size_t) 8 * 1024 * 1024 * 1024; // 8 GiB
  constexpr static unsigned guarantee_alignment = 256;

  /**
   * @brief A memory segment is composed of a start
   *        and size, both referencing bytes.
   *        The tag can either be "" (empty string - free), or any other name,
   *        which means it is occupied by that argument name.
   */
  struct MemorySegment {
    unsigned start;
    size_t size;
    std::string tag;
  };

  std::list<MemorySegment> memory_segments = {{0, max_available_memory, ""}};
  size_t total_memory_required = 0;

  MemoryManager() = default;

  /**
   * @brief Sets the max_available_memory of this manager.
   *        Note: This triggers a free_all to restore the memory_segments
   *        to a valid state. This operation is very disruptive.
   */
  void set_reserved_memory(size_t reserved_memory)
  {
    max_available_memory = reserved_memory;
    free_all();
  }

  /**
   * @brief Reserves a memory request of size requested_size, implementation.
   *        Finds the first available segment.
   *        If there are no available segments of the requested size,
   *        it throws an exception.
   */
  template<typename ArgumentManagerType, typename Argument>
  void reserve(ArgumentManagerType& argument_manager)
  {
    // Tag and requested size
    const auto tag = name<Argument>(argument_manager);
    size_t requested_size = argument_manager.template size<Argument>() * sizeof(typename Argument::type);

    // Size requested should be greater than zero
    if (requested_size == 0) {
      warning_cout << "Warning: MemoryManager: Requested to reserve zero bytes for argument " << tag
                   << ". Did you forget to set_size?" << std::endl;
      requested_size = 1;
    }

    // Aligned requested size
    const size_t aligned_request =
      requested_size + guarantee_alignment - 1 - ((requested_size + guarantee_alignment - 1) % guarantee_alignment);

    if (logger::verbosity() >= 5) {
      verbose_cout << "MemoryManager: Requested to reserve " << requested_size << " B (" << aligned_request
                   << " B aligned) for argument " << tag << std::endl;
    }

    // Finds first free segment providing that space
    auto it = memory_segments.begin();
    for (; it != memory_segments.end(); ++it) {
      if (it->tag == "" && it->size >= aligned_request) {
        break;
      }
    }

    // Complain if no space was available
    if (it == memory_segments.end()) {
      print();
      throw MemoryException(
        "Reserve: Requested size for argument " + tag + " could not be met (" +
        std::to_string(((float) aligned_request) / (1024 * 1024)) + " MiB)");
    }

    // Start of allocation
    const auto start = it->start;
    argument_manager.template set_offset<Argument>(start);

    // Update current segment
    it->start += aligned_request;
    it->size -= aligned_request;
    if (it->size == 0) {
      it = memory_segments.erase(it);
    }

    // Insert an occupied segment
    auto segment = MemorySegment {start, aligned_request, tag};
    memory_segments.insert(it, segment);

    // Update total memory required
    // Note: This can be done accesing the last element in memory_segments
    //       upon every reserve, and keeping the maximum used memory
    total_memory_required = std::max(total_memory_required, max_available_memory - memory_segments.back().size);
  }

  /**
   * @brief Recursive free, implementation for Argument.
   */
  template<typename ArgumentManagerType, typename Argument>
  void free(ArgumentManagerType& argument_manager)
  {
    const auto tag = name<Argument>(argument_manager);

    if (logger::verbosity() >= 5) {
      verbose_cout << "MemoryManager: Requested to free tag " << tag << std::endl;
    }

    auto it = std::find_if(memory_segments.begin(), memory_segments.end(), [&tag](const MemorySegment& segment) {
      return segment.tag == tag;
    });

    if (it == memory_segments.end()) {
      throw StrException("Free: Requested tag could not be found (" + tag + ")");
    }

    // Free found tag
    it->tag = "";

    // Check if previous segment is free, in which case, join
    if (it != memory_segments.begin()) {
      auto previous_it = std::prev(it);
      if (previous_it->tag == "") {
        previous_it->size += it->size;
        // Remove current element, and point to previous one
        it = memory_segments.erase(it);
        it--;
      }
    }

    // Check if next segment is free, in which case, join
    if (std::next(it) != memory_segments.end()) {
      auto next_it = std::next(it);
      if (next_it->tag == "") {
        it->size += next_it->size;
        // Remove next tag
        memory_segments.erase(next_it);
      }
    }
  }

  /**
   * @brief Frees all memory segments, effectively resetting the
   *        available space.
   */
  void free_all() { memory_segments = std::list<MemorySegment> {{0, max_available_memory, ""}}; }

  /**
   * @brief Prints the current state of the memory segments.
   */
  void print()
  {
    info_cout << "Memory segments (MiB):" << std::endl;

    for (auto& segment : memory_segments) {
      std::string name = segment.tag == "" ? "unused" : segment.tag;
      info_cout << name << " (" << ((float) segment.size) / (1024 * 1024) << "), ";
    }
    info_cout << std::endl;

    info_cout << "Max memory required: " << (((float) total_memory_required) / (1024 * 1024)) << " MiB" << std::endl
              << std::endl;
  }
};

/**
 * @brief  Helper struct to iterate in compile time over the
 *         arguments to reserve. Using SFINAE to choose at compile time
 *         whether to reserve on the host or device memory.
 */
template<typename ArgumentManagerType, typename Arguments, typename Enabled = void>
struct MemoryManagerReserve;

template<typename ArgumentManagerType>
struct MemoryManagerReserve<ArgumentManagerType, std::tuple<>, void> {
  constexpr static void reserve(MemoryManager&, MemoryManager&, ArgumentManagerType&) {}
};

template<typename ArgumentManagerType, typename Argument, typename... Arguments>
struct MemoryManagerReserve<
  ArgumentManagerType,
  std::tuple<Argument, Arguments...>,
  typename std::enable_if<std::is_base_of<device_datatype, Argument>::value>::type> {
  constexpr static void reserve(
    MemoryManager& device_memory_manager,
    MemoryManager& host_memory_manager,
    ArgumentManagerType& argument_manager)
  {
    device_memory_manager.reserve<ArgumentManagerType, Argument>(argument_manager);
    MemoryManagerReserve<ArgumentManagerType, std::tuple<Arguments...>>::reserve(
      device_memory_manager, host_memory_manager, argument_manager);
  }
};

template<typename ArgumentManagerType, typename Argument, typename... Arguments>
struct MemoryManagerReserve<
  ArgumentManagerType,
  std::tuple<Argument, Arguments...>,
  typename std::enable_if<std::is_base_of<host_datatype, Argument>::value>::type> {
  constexpr static void reserve(
    MemoryManager& device_memory_manager,
    MemoryManager& host_memory_manager,
    ArgumentManagerType& argument_manager)
  {
    host_memory_manager.reserve<ArgumentManagerType, Argument>(argument_manager);
    MemoryManagerReserve<ArgumentManagerType, std::tuple<Arguments...>>::reserve(
      device_memory_manager, host_memory_manager, argument_manager);
  }
};

/**
 * @brief Helper struct to iterate in compile time over the
 *        arguments to free. Using SFINAE to choose at compile time
 *        whether to free on the host or device memory.
 */
template<typename ArgumentManagerType, typename Arguments, typename Enabled = void>
struct MemoryManagerFree;

template<typename ArgumentManagerType>
struct MemoryManagerFree<ArgumentManagerType, std::tuple<>, void> {
  constexpr static void free(MemoryManager&, MemoryManager&, ArgumentManagerType&) {}
};

template<typename ArgumentManagerType, typename Argument, typename... Arguments>
struct MemoryManagerFree<
  ArgumentManagerType,
  std::tuple<Argument, Arguments...>,
  typename std::enable_if<std::is_base_of<device_datatype, Argument>::value>::type> {
  constexpr static void
  free(MemoryManager& device_memory_manager, MemoryManager& host_memory_manager, ArgumentManagerType& argument_manager)
  {
    device_memory_manager.free<ArgumentManagerType, Argument>(argument_manager);
    MemoryManagerFree<ArgumentManagerType, std::tuple<Arguments...>>::free(
      device_memory_manager, host_memory_manager, argument_manager);
  }
};

template<typename ArgumentManagerType, typename Argument, typename... Arguments>
struct MemoryManagerFree<
  ArgumentManagerType,
  std::tuple<Argument, Arguments...>,
  typename std::enable_if<std::is_base_of<host_datatype, Argument>::value>::type> {
  constexpr static void
  free(MemoryManager& device_memory_manager, MemoryManager& host_memory_manager, ArgumentManagerType& argument_manager)
  {
    // Host memory manager does not free any memory
    //host_memory_manager.free<ArgumentManagerType, Argument>(argument_manager);
    MemoryManagerFree<ArgumentManagerType, std::tuple<Arguments...>>::free(
      device_memory_manager, host_memory_manager, argument_manager);
  }
};
