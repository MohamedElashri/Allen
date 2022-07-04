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
#ifdef ALLEN_STANDALONE

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

  public:
    __host__ buffer(Allen::Store::memory_manager_t<S>& mem_manager, const std::string& tag) :
      m_mem_manager(mem_manager), m_tag(tag)
    {}

    __host__ buffer(Allen::Store::memory_manager_t<S>& mem_manager, const std::string& tag, size_t size) :
      m_mem_manager(mem_manager), m_tag(tag),
      m_span(reinterpret_cast<T*>(m_mem_manager.reserve(m_tag, size * sizeof(T))), size)
    {}

    // Allow to move the object
    __host__ buffer(buffer&& o) : m_mem_manager(o.m_mem_manager), m_tag(o.m_tag), m_span(o.m_span)
    {
      // Set o span to empty to avoid the data being freed in the destructor of o
      o.m_span = gsl::span<T> {};
    }

    __host__ ~buffer()
    {
      if (m_span.size() != 0) {
        m_mem_manager.free(m_tag);
      }
    }

    __host__ auto begin() const { return m_span.begin(); }

    __host__ auto end() const { return m_span.end(); }

    constexpr __host__ size_t size() const { return m_span.size(); }

    constexpr __host__ size_t sizebytes() const
    {
      static_assert(S == Allen::Store::Scope::Host);
      return m_span.sizebytes();
    }

    constexpr __host__ T* data() const { return m_span.data(); }

    __host__ void resize(size_t size)
    {
      if (m_span.size() != 0) {
        m_mem_manager.free(m_tag);
      }
      m_span = gsl::span<T> {reinterpret_cast<T*>(m_mem_manager.reserve(m_tag, size * sizeof(T))), size};
    }

    __host__ gsl::span<T> to_span() { return m_span; }

    __host__ operator gsl::span<T>() { return m_span; }

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
    std::vector<T> m_vector;

  public:
    __host__ buffer(size_t size) : m_vector(size) {}

    // Allow to move the object
    __host__ buffer(buffer&& o) : m_vector{std::move(o.m_vector)} {}

    __host__ auto begin() const { return m_vector.begin(); }

    __host__ auto end() const { return m_vector.end(); }

    constexpr __host__ size_t size() const { return m_vector.size(); }

    constexpr __host__ size_t sizebytes() const { return m_vector.sizebytes(); }

    constexpr __host__ T* data() const { return m_vector.data(); }

    __host__ void resize(size_t size) { m_vector.resize(size); }

    __host__ gsl::span<T> to_span() { return m_vector; }

    __host__ operator gsl::span<T>() { return m_vector; }

    constexpr __host__ T& operator[](int i) { return m_vector[i]; }

    constexpr __host__ const T& operator[](int i) const { return m_vector[i]; }

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
