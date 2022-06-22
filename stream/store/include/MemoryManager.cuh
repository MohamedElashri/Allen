/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <list>
#include <algorithm>
#include "Common.h"
#include "Logger.h"
#include "Configuration.cuh"
#include "ArgumentData.cuh"
#include "Store.cuh"

namespace Allen::Store {

  namespace memory_manager_details {
    // Distinguish between Host and Device memory managers
    struct Host {
      constexpr static auto scope = Allen::Store::Scope::Host;
      static void free(void* ptr) { Allen::free_host(ptr); }
      static void malloc(void** ptr, size_t s) { Allen::malloc_host(ptr, s); }
    };
    struct Device {
      constexpr static auto scope = Allen::Store::Scope::Device;
      static void free(void* ptr) { Allen::free(ptr); }
      static void malloc(void** ptr, size_t s) { Allen::malloc(ptr, s); }
    };

    // Distinguish between single and multi alloc memory managers
    struct SingleAlloc {
    };
    struct MultiAlloc {
    };

  } // namespace memory_manager_details

  template<typename Target, typename AllocPolicy>
  class MemoryManager;

  /**
   * @brief This memory manager allocates a single chunk of memory at the beginning,
   *        and reserves / frees using this memory chunk from that point onwards.
   */
  template<typename Target>
  class MemoryManager<Target, memory_manager_details::SingleAlloc> : public Target {
  private:
    std::string m_name = "Memory manager";
    size_t m_max_available_memory = 0;
    unsigned m_guaranteed_alignment = 512;
    char* m_base_pointer = nullptr;
    size_t m_total_memory_required = 0;

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

  public:
    MemoryManager() = default;
    MemoryManager(const std::string& name) : m_name {name} {}
    MemoryManager(const std::string& name, const size_t memory_size, const unsigned memory_alignment) :
      m_name {name}, m_max_available_memory {memory_size}, m_guaranteed_alignment {memory_alignment}
    {
      if (m_base_pointer) Target::free(m_base_pointer);
      Target::malloc(reinterpret_cast<void**>(&m_base_pointer), memory_size);
    }

    /**
     * @brief Sets the m_max_available_memory of this manager.
     *        Note: This triggers a free_all to restore the m_memory_segments
     *        to a valid state. This operation is very disruptive.
     */
    void reserve_memory(size_t memory_size, const unsigned memory_alignment)
    {
      if (m_base_pointer) Target::free(m_base_pointer);
      Target::malloc(reinterpret_cast<void**>(&m_base_pointer), memory_size);

      m_guaranteed_alignment = memory_alignment;
      m_max_available_memory = memory_size;
    }

    char* reserve(const std::string& tag, size_t requested_size)
    {
      // Size requested should be greater than zero
      if (requested_size == 0) {
        constexpr int zero_size_message_verbosity = logger::debug;
        if (logger::verbosity() >= zero_size_message_verbosity) {
          warning_cout << "MemoryManager: Requested to reserve zero bytes for argument " << tag
                       << ". Did you forget to set_size?" << std::endl;
        }
        requested_size = 1;
      }

      // Aligned requested size
      const size_t aligned_request = requested_size + m_guaranteed_alignment - 1 -
                                     ((requested_size + m_guaranteed_alignment - 1) % m_guaranteed_alignment);

      if (logger::verbosity() >= 5) {
        verbose_cout << "MemoryManager: Requested to reserve " << requested_size << " B (" << aligned_request
                     << " B aligned) for argument " << tag << std::endl;
      }

      // Finds first free segment providing sufficient space
      auto it = std::find_if(m_memory_segments.begin(), m_memory_segments.end(), [&](const auto& ms) {
        return ms.tag == "" && ms.size >= aligned_request;
      });

      // Complain if no space was available
      if (it == m_memory_segments.end()) {
        print();
        throw MemoryException(
          "Reserve: Requested size for argument " + tag + " could not be met (" +
          std::to_string(((float) aligned_request) / (1000.f * 1000.f)) + " MB)");
      }

      // Start of allocation
      const auto start = it->start;

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
      m_total_memory_required =
        std::max(m_total_memory_required, m_max_available_memory - m_memory_segments.back().size);

      return m_base_pointer + start;
    }

    /**
     * @brief Reserves a memory request of size requested_size, implementation.
     *        Finds the first available segment.
     *        If there are no available segments of the requested size,
     *        it throws an exception.
     */
    void reserve(ArgumentData& argument) { argument.set_pointer(reserve(argument.name(), argument.sizebytes())); }

    void free(const std::string& tag)
    {
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
          it = std::prev(m_memory_segments.erase(it));
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
     * @brief Recursive free, implementation for Argument.
     */
    void free(ArgumentData& argument) { free(argument.name()); }

    void test_alignment()
    {
      for (const auto it : m_memory_segments) {
        if (it.tag != "") {
          // Note: Do an assert
          if (!((it.start % m_guaranteed_alignment) == 0)) {
            info_cout << "Found misaligned entry: " << it.tag << "\n";
            print();
          }
        }
      }
    }

    /**
     * @brief Frees all memory segments, effectively resetting the
     *        available space.
     */
    void free_all() { m_memory_segments = {{0, m_max_available_memory, ""}}; }

    /**
     * @brief Prints the current state of the memory segments.
     */
    void print()
    {
      info_cout << m_name << " segments (MB):" << std::endl;
      for (auto& segment : m_memory_segments) {
        std::string name = segment.tag == "" ? "unused" : segment.tag;
        info_cout << name << " (" << ((float) segment.size) / (1000.f * 1000.f) << "), ";
      }
      info_cout << "\nMax memory required: " << (((float) m_total_memory_required) / (1000.f * 1000.f)) << " MB"
                << "\n\n";
    }
  };

  /**
   * @brief This memory manager allocates / frees using the backend calls (eg. Allen::malloc, Allen::free).
   *        It is slower but better at debugging out-of-bound accesses.
   */
  template<typename Target>
  class MemoryManager<Target, memory_manager_details::MultiAlloc> : public Target {
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
    std::unordered_map<std::string, MemorySegment> m_memory_segments {};

  public:
    MemoryManager() = default;

    MemoryManager(std::string name) : m_name {std::move(name)} {}

    /**
     * @brief This MultiAlloc MemoryManager does not reserve memory upon startup.
     */
    void reserve_memory(size_t, const unsigned) {}

    char* reserve(const std::string& tag, size_t requested_size)
    {
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

      Target::malloc(reinterpret_cast<void**>(&memory_pointer), requested_size);

      // Add the pointer to the memory segments map
      m_memory_segments[tag] = MemorySegment {memory_pointer, requested_size};

      m_total_memory_required += requested_size;

      return memory_pointer;
    }

    /**
     * @brief Allocates a segment of the requested size.
     */
    void reserve(ArgumentData& argument) { argument.set_pointer(reserve(argument.name(), argument.sizebytes())); }

    void free(const std::string& tag, void* pointer)
    {
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

      Target::free(pointer);

      m_total_memory_required -= it->second.size;

      m_memory_segments.erase(tag);
    }

    /**
     * @brief Frees the requested argument.
     */
    void free(ArgumentData& argument) { free(argument.name(), argument.pointer()); }

    /**
     * @brief Frees all memory segments, effectively resetting the
     *        available space.
     */
    void free_all()
    {
      for (const auto& it : m_memory_segments) {
        Target::free(it.second.pointer);
      }
      m_memory_segments.clear();
    }

    void test_alignment() {}

    /**
     * @brief Prints the current state of the memory segments.
     */
    void print()
    {
      info_cout << m_name << " segments (MB):" << std::endl;
      for (auto const& [name, segment] : m_memory_segments) {
        info_cout << name << " (" << ((float) segment.size) / (1000.f * 1000.f) << "), ";
      }
      info_cout << "\nMax memory required: " << (((float) m_total_memory_required) / (1000.f * 1000.f)) << " MB"
                << "\n\n";
    }
  };

  struct MemoryManagerHelper {
    template<typename HostMemoryManager, typename DeviceMemoryManager>
    static void reserve(
      HostMemoryManager& host_memory_manager,
      DeviceMemoryManager& device_memory_manager,
      UnorderedStore& store,
      const LifetimeDependencies& in_dependencies)
    {
      for (const auto& arg_name : in_dependencies.arguments) {
        auto& arg = store.at(arg_name);
        if (arg.scope() == host_memory_manager.scope) {
          host_memory_manager.reserve(arg);
        }
        else if (arg.scope() == device_memory_manager.scope) {
          device_memory_manager.reserve(arg);
        }
        else {
          throw std::runtime_error("argument scope not recognized");
        }
      }
    }

    /**
     * @brief Frees memory buffers specified by out_dependencies.
     *        Host memory buffers are NOT freed, which is required by the
     *        current Allen memory model.
     */
    template<typename HostMemoryManager, typename DeviceMemoryManager>
    static void free(
      HostMemoryManager& host_memory_manager,
      DeviceMemoryManager& device_memory_manager,
      UnorderedStore& store,
      const LifetimeDependencies& out_dependencies)
    {
      for (const auto& arg_name : out_dependencies.arguments) {
        auto& arg = store.at(arg_name);
        if (arg.scope() == device_memory_manager.scope) {
          device_memory_manager.free(arg);
        }
        else if (arg.scope() != host_memory_manager.scope) {
          throw std::runtime_error("argument scope not recognized");
        }
      }
    }
  };

#ifdef MEMORY_MANAGER_MULTI_ALLOC
  template<typename T>
  using memory_manager_t = MemoryManager<T, memory_manager_details::MultiAlloc>;
#else
  template<typename T>
  using memory_manager_t = MemoryManager<T, memory_manager_details::SingleAlloc>;
#endif

  using host_memory_manager_t = memory_manager_t<memory_manager_details::Host>;
  using device_memory_manager_t = memory_manager_t<memory_manager_details::Device>;

} // namespace Allen::Store
