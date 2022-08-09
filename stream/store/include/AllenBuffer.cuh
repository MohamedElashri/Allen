/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <MemoryManager.cuh>
#include <gsl/gsl>

namespace Allen {
#if defined(ALLEN_STANDALONE) || !defined(TARGET_DEVICE_CPU)

  /**
   * @brief Standalone buffer: Uses an instance of the memory manager
   *        to keep its store and frees upon destruction.
   */
  template<Store::Scope S, typename T>
  struct buffer {
  private:
    Allen::Store::memory_manager_t<S>& m_mem_manager;
    const std::string m_tag;
    gsl::span<T> m_span {};
    bool m_allocated = false;

  public:
    __host__ buffer(Allen::Store::memory_manager_t<S>& mem_manager, const std::string& tag) :
      m_mem_manager(mem_manager), m_tag(tag)
    {}

    __host__ buffer(Allen::Store::memory_manager_t<S>& mem_manager, const std::string& tag, size_t size) :
      m_mem_manager(mem_manager), m_tag(tag),
      m_span(reinterpret_cast<T*>(m_mem_manager.reserve(m_tag, size * sizeof(T))), size), m_allocated(true)
    {}

    // Allow to move the object
    __host__ buffer(buffer&& o) :
      m_mem_manager(o.m_mem_manager), m_tag(o.m_tag), m_span(o.m_span), m_allocated(o.m_allocated)
    {
      // Set o span to empty to avoid the data being freed in the destructor of o
      o.m_span = gsl::span<T> {};
    }

    __host__ ~buffer()
    {
      if (m_allocated) {
        m_mem_manager.free(m_tag);
      }
    }

    __host__ auto begin() const
    {
      static_assert(S == Allen::Store::Scope::Host);
      return m_span.begin();
    }

    __host__ auto end() const
    {
      static_assert(S == Allen::Store::Scope::Host);
      return m_span.end();
    }

    constexpr __host__ size_t size() const { return m_span.size(); }

    constexpr __host__ size_t sizebytes() const { return m_span.size() * sizeof(T); }

    constexpr __host__ T* data() const { return m_span.data(); }

    constexpr __host__ T* data() { return m_span.data(); }

    __host__ void resize(size_t size)
    {
      if (m_allocated) {
        m_mem_manager.free(m_tag);
      }
      m_allocated = true;
      m_span = gsl::span<T> {reinterpret_cast<T*>(m_mem_manager.reserve(m_tag, size * sizeof(T))), size};
    }

    __host__ gsl::span<T> get() { return m_span; }

    __host__ operator gsl::span<T>() { return get(); }

    constexpr __host__ T& operator[](int i)
    {
      static_assert(S == Allen::Store::Scope::Host);
      return m_span[i];
    }

    constexpr __host__ const T& operator[](int i) const
    {
      static_assert(S == Allen::Store::Scope::Host);
      return m_span[i];
    }

    buffer(const buffer&) = delete;
    buffer& operator=(const buffer&) = delete;
    buffer& operator=(buffer&&) = delete;
  };

#else

  /**
   * @brief Non standalone buffer: Uses a std::vector to store its data.
   *        The scope is irrelevant, as it is always stored in the host.
   */
  template<Store::Scope, typename T>
  struct buffer {
  private:
    std::vector<bool_as_char_t<T>> m_vector;

  public:
    __host__ buffer(const Allen::Store::host_memory_manager_t&, const std::string&) : m_vector {} {}

    __host__ buffer(size_t size) : m_vector(size) {}

    // Allow to move the object
    __host__ buffer(buffer&& o) : m_vector {std::move(o.m_vector)} {}

    __host__ auto begin() const { return m_vector.begin(); }

    __host__ auto end() const { return m_vector.end(); }

    constexpr __host__ size_t size() const { return m_vector.size(); }

    constexpr __host__ size_t sizebytes() const { return m_vector.size() * sizeof(T); }

    constexpr __host__ auto data() const { return reinterpret_cast<const T*>(m_vector.data()); }

    constexpr __host__ auto data() { return reinterpret_cast<T*>(m_vector.data()); }

    __host__ void resize(size_t size) { m_vector.resize(size); }

    __host__ gsl::span<T> get()
    {
      if constexpr (std::is_same_v<std::decay_t<T>, bool>) {
        return {Allen::forward_type_t<T, bool*>(m_vector.data()), m_vector.size()};
      }
      else {
        return m_vector;
      }
    }

    __host__ operator gsl::span<T>() { return get(); }

    constexpr __host__ T& operator[](int i)
    {
      if constexpr (std::is_same_v<std::decay_t<T>, bool>) {
        return Allen::forward_type_t<T&, bool>(m_vector[i]);
      }
      else {
        return m_vector[i];
      }
    }

    constexpr __host__ const T& operator[](int i) const
    {
      if constexpr (std::is_same_v<std::decay_t<T>, bool>) {
        return Allen::forward_type_t<const T&, bool>(m_vector[i]);
      }
      else {
        return m_vector[i];
      }
    }

    buffer(const buffer&) = delete;
    buffer& operator=(const buffer&) = delete;
    buffer& operator=(buffer&&) = delete;
  };
#endif

  template<typename T>
  using host_buffer = buffer<Allen::Store::Scope::Host, T>;

  template<typename T>
  using device_buffer = buffer<Allen::Store::Scope::Device, T>;
} // namespace Allen
