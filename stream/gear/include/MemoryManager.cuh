/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <list>
#include <algorithm>
#include "Common.h"
#include "Logger.h"

namespace memory_manager_details {
  // Distinguish between Host and Device memory managers
  struct Host {
  };
  struct Device {
  };

  // Distinguish between single and multi alloc memory managers
  struct SingleAlloc {
  };
  struct MultiAlloc {
  };
} // namespace memory_manager_details

template<typename Target, typename AllocPolicy>
struct MemoryManager;

/**
 * @brief This memory manager allocates a single chunk of memory at the beginning,
 *        and reserves / frees using this memory chunk from that point onwards.
 */
template<typename Target>
struct MemoryManager<Target, memory_manager_details::SingleAlloc> {
private:
  char* m_base_pointer = nullptr;
  size_t m_max_available_memory = 0;
  unsigned m_guaranteed_alignment = 512;

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

  std::list<MemorySegment> m_memory_segments = {{0, m_max_available_memory, ""}};
  size_t m_total_memory_required = 0;
  std::string m_name = "Memory manager";

public:
  MemoryManager() = default;

  MemoryManager(const std::string& name) :
    m_name(name)
  {}

  /**
   * @brief Sets the m_max_available_memory of this manager.
   *        Note: This triggers a free_all to restore the m_memory_segments
   *        to a valid state. This operation is very disruptive.
   */
  void reserve_memory(size_t memory_size, const unsigned memory_alignment)
  {
    if constexpr (std::is_same_v<Target, memory_manager_details::Host>) {
      if (m_base_pointer != nullptr) {
        Allen::free_host(m_base_pointer);
      }
      Allen::malloc_host((void**) &m_base_pointer, memory_size);
    }
    else {
      if (m_base_pointer != nullptr) {
        Allen::free(m_base_pointer);
      }
      Allen::malloc((void**) &m_base_pointer, memory_size);
    }

    m_guaranteed_alignment = memory_alignment;
    m_max_available_memory = memory_size;
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
    const auto tag = argument_manager.template name<Argument>();
    size_t requested_size = argument_manager.template size<Argument>() * sizeof(typename Argument::type);

    // Size requested should be greater than zero
    if (requested_size == 0) {
      warning_cout << "Warning: MemoryManager: Requested to reserve zero bytes for argument " << tag
                   << ". Did you forget to set_size?" << std::endl;
      requested_size = 1;
    }

    // Aligned requested size
    const size_t aligned_request = requested_size + m_guaranteed_alignment - 1 -
                                   ((requested_size + m_guaranteed_alignment - 1) % m_guaranteed_alignment);

    if (logger::verbosity() >= 5) {
      verbose_cout << "MemoryManager: Requested to reserve " << requested_size << " B (" << aligned_request
                   << " B aligned) for argument " << tag << std::endl;
    }

    // Finds first free segment providing that space
    auto it = m_memory_segments.begin();
    for (; it != m_memory_segments.end(); ++it) {
      if (it->tag == "" && it->size >= aligned_request) {
        break;
      }
    }

    // Complain if no space was available
    if (it == m_memory_segments.end()) {
      print();
      throw MemoryException(
        "Reserve: Requested size for argument " + tag + " could not be met (" +
        std::to_string(((float) aligned_request) / (1024 * 1024)) + " MiB)");
    }

    // Start of allocation
    const auto start = it->start;
    argument_manager.template set_pointer<Argument>(m_base_pointer + start);

    // Update current segment
    it->start += aligned_request;
    it->size -= aligned_request;
    if (it->size == 0) {
      it = m_memory_segments.erase(it);
    }

    // Insert an occupied segment
    auto segment = MemorySegment {start, aligned_request, tag};
    m_memory_segments.insert(it, segment);

    // Update total memory required
    // Note: This can be done accesing the last element in m_memory_segments
    //       upon every reserve, and keeping the maximum used memory
    m_total_memory_required = std::max(m_total_memory_required, m_max_available_memory - m_memory_segments.back().size);
  }

  /**
   * @brief Recursive free, implementation for Argument.
   */
  template<typename ArgumentManagerType, typename Argument>
  void free(ArgumentManagerType& argument_manager)
  {
    const auto tag = argument_manager.template name<Argument>();

    if (logger::verbosity() >= 5) {
      verbose_cout << "MemoryManager: Requested to free tag " << tag << std::endl;
    }

    auto it = std::find_if(m_memory_segments.begin(), m_memory_segments.end(), [&tag](const MemorySegment& segment) {
      return segment.tag == tag;
    });

    if (it == m_memory_segments.end()) {
      throw StrException("MemoryManager free: Requested tag could not be found (" + tag + ")");
    }

    // Free found tag
    it->tag = "";

    // Check if previous segment is free, in which case, join
    if (it != m_memory_segments.begin()) {
      auto previous_it = std::prev(it);
      if (previous_it->tag == "") {
        previous_it->size += it->size;
        // Remove current element, and point to previous one
        it = m_memory_segments.erase(it);
        it--;
      }
    }

    // Check if next segment is free, in which case, join
    if (std::next(it) != m_memory_segments.end()) {
      auto next_it = std::next(it);
      if (next_it->tag == "") {
        it->size += next_it->size;
        // Remove next tag
        m_memory_segments.erase(next_it);
      }
    }
  }

  /**
   * @brief Frees all memory segments, effectively resetting the
   *        available space.
   */
  void free_all() { m_memory_segments = std::list<MemorySegment> {{0, m_max_available_memory, ""}}; }

  /**
   * @brief Prints the current state of the memory segments.
   */
  void print()
  {
    info_cout << m_name << " segments (MiB):" << std::endl;
    for (auto& segment : m_memory_segments) {
      std::string name = segment.tag == "" ? "unused" : segment.tag;
      info_cout << name << " (" << ((float) segment.size) / (1024 * 1024) << "), ";
    }
    info_cout << "\nMax memory required: " << (((float) m_total_memory_required) / (1024 * 1024)) << " MiB"
              << "\n\n";
  }
};

/**
 * @brief This memory manager allocates / frees using the backend calls (eg. Allen::malloc, Allen::free).
 *        It is slower but better at debugging out-of-bound accesses.
 */
template<typename Target>
struct MemoryManager<Target, memory_manager_details::MultiAlloc> {
private:
  size_t m_total_memory_required = 0;
  std::string m_name = "Memory manager";

  /**
   * @brief A memory segment, in the case of MultiAlloc policy,
   *        consists just of a name to pointer association.
   */
  struct MemorySegment {
    char* pointer;
    size_t size;
  };
  std::map<std::string, MemorySegment> m_memory_segments {};

public:
  MemoryManager() = default;

  MemoryManager(const std::string& name) : m_name(name) {}

  /**
   * @brief This MultiAlloc MemoryManager does not reserve memory upon startup.
   */
  void reserve_memory(size_t, const unsigned)
  {
    // Note: This function invokes free_all() in order to preserve the
    //       same behaviour as SingleAlloc memory managers.
    free_all();
  }

  /**
   * @brief Allocates a segment of the requested size.
   */
  template<typename ArgumentManagerType, typename Argument>
  void reserve(ArgumentManagerType& argument_manager)
  {
    // Tag and requested size
    const auto tag = argument_manager.template name<Argument>();
    size_t requested_size = argument_manager.template size<Argument>() * sizeof(typename Argument::type);

    // Verify the pointer didn't exist in the memory segments map
    const auto it = m_memory_segments.find(tag);
    if (it != m_memory_segments.end()) {
      print();
      throw MemoryException("MemoryManager reserve: Requested to reserve tag " + tag + " but it already exists");
    }

    // Size requested should be greater than zero
    if (requested_size == 0) {
      warning_cout << "Warning: MemoryManager: Requested to reserve zero bytes for argument " << tag
                   << ". Did you forget to set_size?" << std::endl;
      requested_size = 1;
    }

    // We will allocate in a char*
    char* memory_pointer;

    if constexpr (std::is_same_v<Target, memory_manager_details::Host>) {
      Allen::malloc_host((void**) &memory_pointer, requested_size);
    }
    else {
      Allen::malloc((void**) &memory_pointer, requested_size);
    }

    argument_manager.template set_pointer<Argument>(memory_pointer);

    // Add the pointer to the memory segments map
    m_memory_segments[tag] = MemorySegment {memory_pointer, requested_size};

    m_total_memory_required += requested_size;
  }

  /**
   * @brief Frees the requested argument.
   */
  template<typename ArgumentManagerType, typename Argument>
  void free(ArgumentManagerType& argument_manager)
  {
    const auto tag = argument_manager.template name<Argument>();

    // Verify the pointer existed in the memory segments map
    const auto it = m_memory_segments.find(tag);
    if (it == m_memory_segments.end()) {
      print();
      throw MemoryException(
        "MemoryManager free: Requested to free tag " + tag + " but it was not registered with this MemoryManager");
    }

    if (logger::verbosity() >= 5) {
      verbose_cout << "MemoryManager: Requested to free tag " << tag << std::endl;
    }

    if constexpr (std::is_same_v<Target, memory_manager_details::Host>) {
      Allen::free_host(argument_manager.template pointer<Argument>());
    }
    else {
      Allen::free(argument_manager.template pointer<Argument>());
    }

    m_memory_segments.erase(tag);

    m_total_memory_required -= argument_manager.template size<Argument>() * sizeof(typename Argument::type);
  }

  /**
   * @brief Frees all memory segments, effectively resetting the
   *        available space.
   */
  void free_all()
  {
    for (const auto& it : m_memory_segments) {
      if constexpr (std::is_same_v<Target, memory_manager_details::Host>) {
        Allen::free_host(it.second.pointer);
      }
      else {
        Allen::free(it.second.pointer);
      }
    }
    m_memory_segments.clear();
  }

  /**
   * @brief Prints the current state of the memory segments.
   */
  void print()
  {
    info_cout << m_name << " segments (MiB):" << std::endl;
    for (auto const& [name, segment] : m_memory_segments) {
      info_cout << name << " (" << ((float) segment.size) / (1024 * 1024) << "), ";
    }
    info_cout << "\nMax memory required: " << (((float) m_total_memory_required) / (1024 * 1024)) << " MiB"
              << "\n\n";
  }
};

/**
 * @brief  Helper struct to iterate in compile time over the
 *         arguments to reserve. Using SFINAE to choose at compile time
 *         whether to reserve on the host or device memory.
 */
template<
  typename HostMemoryManager,
  typename DeviceMemoryManager,
  typename ArgumentManagerType,
  typename Arguments,
  typename Enabled = void>
struct MemoryManagerReserve;

template<typename HostMemoryManager, typename DeviceMemoryManager, typename ArgumentManagerType>
struct MemoryManagerReserve<HostMemoryManager, DeviceMemoryManager, ArgumentManagerType, std::tuple<>, void> {
  constexpr static void reserve(HostMemoryManager&, DeviceMemoryManager&, ArgumentManagerType&) {}
};

template<
  typename HostMemoryManager,
  typename DeviceMemoryManager,
  typename ArgumentManagerType,
  typename Argument,
  typename... Arguments>
struct MemoryManagerReserve<
  HostMemoryManager,
  DeviceMemoryManager,
  ArgumentManagerType,
  std::tuple<Argument, Arguments...>,
  typename std::enable_if<std::is_base_of<device_datatype, Argument>::value>::type> {
  constexpr static void reserve(
    HostMemoryManager& host_memory_manager,
    DeviceMemoryManager& device_memory_manager,
    ArgumentManagerType& argument_manager)
  {
    device_memory_manager.template reserve<ArgumentManagerType, Argument>(argument_manager);
    MemoryManagerReserve<HostMemoryManager, DeviceMemoryManager, ArgumentManagerType, std::tuple<Arguments...>>::
      reserve(host_memory_manager, device_memory_manager, argument_manager);
  }
};

template<
  typename HostMemoryManager,
  typename DeviceMemoryManager,
  typename ArgumentManagerType,
  typename Argument,
  typename... Arguments>
struct MemoryManagerReserve<
  HostMemoryManager,
  DeviceMemoryManager,
  ArgumentManagerType,
  std::tuple<Argument, Arguments...>,
  typename std::enable_if<std::is_base_of<host_datatype, Argument>::value>::type> {
  constexpr static void reserve(
    HostMemoryManager& host_memory_manager,
    DeviceMemoryManager& device_memory_manager,
    ArgumentManagerType& argument_manager)
  {
    host_memory_manager.template reserve<ArgumentManagerType, Argument>(argument_manager);
    MemoryManagerReserve<HostMemoryManager, DeviceMemoryManager, ArgumentManagerType, std::tuple<Arguments...>>::
      reserve(host_memory_manager, device_memory_manager, argument_manager);
  }
};

/**
 * @brief Helper struct to iterate in compile time over the
 *        arguments to free. Using SFINAE to choose at compile time
 *        whether to free on the host or device memory.
 */
template<
  typename HostMemoryManager,
  typename DeviceMemoryManager,
  typename ArgumentManagerType,
  typename Arguments,
  typename Enabled = void>
struct MemoryManagerFree;

template<typename HostMemoryManager, typename DeviceMemoryManager, typename ArgumentManagerType>
struct MemoryManagerFree<HostMemoryManager, DeviceMemoryManager, ArgumentManagerType, std::tuple<>, void> {
  constexpr static void free(HostMemoryManager&, DeviceMemoryManager&, ArgumentManagerType&) {}
};

template<
  typename HostMemoryManager,
  typename DeviceMemoryManager,
  typename ArgumentManagerType,
  typename Argument,
  typename... Arguments>
struct MemoryManagerFree<
  HostMemoryManager,
  DeviceMemoryManager,
  ArgumentManagerType,
  std::tuple<Argument, Arguments...>,
  typename std::enable_if<std::is_base_of<device_datatype, Argument>::value>::type> {
  constexpr static void free(
    HostMemoryManager& host_memory_manager,
    DeviceMemoryManager& device_memory_manager,
    ArgumentManagerType& argument_manager)
  {
    device_memory_manager.template free<ArgumentManagerType, Argument>(argument_manager);
    MemoryManagerFree<HostMemoryManager, DeviceMemoryManager, ArgumentManagerType, std::tuple<Arguments...>>::free(
      host_memory_manager, device_memory_manager, argument_manager);
  }
};

template<
  typename HostMemoryManager,
  typename DeviceMemoryManager,
  typename ArgumentManagerType,
  typename Argument,
  typename... Arguments>
struct MemoryManagerFree<
  HostMemoryManager,
  DeviceMemoryManager,
  ArgumentManagerType,
  std::tuple<Argument, Arguments...>,
  typename std::enable_if<std::is_base_of<host_datatype, Argument>::value>::type> {
  constexpr static void free(
    HostMemoryManager& host_memory_manager,
    DeviceMemoryManager& device_memory_manager,
    ArgumentManagerType& argument_manager)
  {
    // Host memory manager does not free any memory
    // host_memory_manager.template free<ArgumentManagerType, Argument>(argument_manager);
    MemoryManagerFree<HostMemoryManager, DeviceMemoryManager, ArgumentManagerType, std::tuple<Arguments...>>::free(
      host_memory_manager, device_memory_manager, argument_manager);
  }
};
