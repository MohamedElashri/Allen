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
#include <variant>

namespace Allen {
  namespace details {
    /**
     * @brief Standalone backend for the buffer.
     * @details Uses the memory manager provided by the store
     *          to free and reserve the buffer.
     */
    template<Store::Scope S, typename T>
    struct standalone_buffer {
    private:
      Allen::Store::memory_manager_t<S>* m_mem_manager = nullptr;
      const std::string m_tag = "";
      gsl::span<T> m_span {};
      bool m_allocated = false;

    public:
      __host__ standalone_buffer() {}
      __host__ standalone_buffer(Allen::Store::memory_manager_t<S>& mem_manager, const std::string& tag) :
        m_mem_manager(&mem_manager), m_tag(tag)
      {}
      __host__ standalone_buffer(Allen::Store::memory_manager_t<S>& mem_manager, const std::string& tag, size_t size) :
        m_mem_manager(&mem_manager), m_tag(tag),
        m_span(reinterpret_cast<T*>(m_mem_manager->reserve(m_tag, size * sizeof(T))), size), m_allocated(true)
      {}
      __host__ standalone_buffer(standalone_buffer&& o) :
        m_mem_manager(o.m_mem_manager), m_tag(o.m_tag), m_span(o.m_span), m_allocated(o.m_allocated)
      {
        // Set o allocated to false to avoid the data being freed in the destructor of o
        o.m_allocated = false;
      }
      __host__ ~standalone_buffer()
      {
        if (m_allocated) {
          m_mem_manager->free(m_tag);
        }
      }
      __host__ void resize(size_t size)
      {
        if (m_allocated) {
          m_mem_manager->free(m_tag);
        }
        m_allocated = true;
        m_span = gsl::span<T> {reinterpret_cast<T*>(m_mem_manager->reserve(m_tag, size * sizeof(T))), size};
      }
      __host__ gsl::span<T> get() { return m_span; }
      __host__ gsl::span<const T> get() const { return m_span; }
    };

    /**
     * @brief Non-standalone backend for the buffer, used in Gaudi sequencer.
     * @details Uses a std::vector as a backend.
     */
    template<typename T>
    struct nonstandalone_buffer {
    private:
      std::vector<bool_as_char_t<T>> m_vector;

    public:
      __host__ nonstandalone_buffer() : m_vector {} {}
      __host__ nonstandalone_buffer(size_t size) : m_vector(size) {}
      __host__ nonstandalone_buffer(nonstandalone_buffer&& o) : m_vector {std::move(o.m_vector)} {}
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
      __host__ gsl::span<const T> get() const
      {
        if constexpr (std::is_same_v<std::decay_t<T>, bool>) {
          return {Allen::forward_type_t<T, bool*>(m_vector.data()), m_vector.size()};
        }
        else {
          return m_vector;
        }
      }
    };
  } // namespace details

  /**
   * @brief A buffer that can be independently resized or operated upon.
   *        It can be moved, but it cannot be copied.
   * @details A buffer can be used as an independent datatype, and it requires
   *          supporting both the Allen and the Gaudi sequencer. This distinction
   *          can only be made in runtime, and therefore the following implementation
   *          needs to be able to manage the memory associated with the object in either case.
   */
  template<Store::Scope S, typename T>
  struct buffer {
  private:
    std::variant<details::standalone_buffer<S, T>, details::nonstandalone_buffer<T>> m_buffer;
    gsl::span<T> m_span;

  public:
    __host__ buffer(Allen::Store::memory_manager_t<S>& mem_manager, const std::string& tag) :
      m_buffer {details::standalone_buffer<S, T> {mem_manager, tag}}
    {
      m_span = std::get<details::standalone_buffer<S, T>>(m_buffer).get();
    }
    __host__ buffer(Allen::Store::memory_manager_t<S>& mem_manager, const std::string& tag, size_t size) :
      m_buffer {details::standalone_buffer<S, T> {mem_manager, tag, size}}
    {
      m_span = std::get<details::standalone_buffer<S, T>>(m_buffer).get();
    }
    __host__ buffer(size_t size) : m_buffer {details::nonstandalone_buffer<T> {size}}
    {
      m_span = std::get<details::nonstandalone_buffer<T>>(m_buffer).get();
    }
    __host__ buffer(buffer&&) = default;
    __host__ buffer& operator=(buffer&&) = default;

    __host__ void resize(size_t size)
    {
      std::visit(
        [&](auto& buf) {
          buf.resize(size);
          m_span = buf.get();
        },
        m_buffer);
    }
    constexpr __host__ gsl::span<T> get() { return m_span; }
    constexpr __host__ gsl::span<const T> get() const { return m_span; }
    constexpr __host__ auto begin() const
    {
      static_assert(S == Allen::Store::Scope::Host);
      return get().begin();
    }
    constexpr __host__ auto end() const
    {
      static_assert(S == Allen::Store::Scope::Host);
      return get().end();
    }
    constexpr __host__ auto size() const { return get().size(); }
    constexpr __host__ auto size_bytes() const { return get().size_bytes(); }
    constexpr __host__ auto data() const { return get().data(); }
    constexpr __host__ auto data() { return get().data(); }
    constexpr __host__ auto& operator[](int i)
    {
      static_assert(S == Allen::Store::Scope::Host);
      return get()[i];
    }
    constexpr __host__ const auto& operator[](int i) const
    {
      static_assert(S == Allen::Store::Scope::Host);
      return get()[i];
    }
    constexpr __host__ operator gsl::span<T>() { return get(); }
    constexpr __host__ auto operator-> () const { return data(); }
    constexpr __host__ operator T*() const { return data(); }
    constexpr __host__ auto empty() const { return m_span.empty(); }
    constexpr __host__ auto subspan(const std::size_t offset) const { return m_span.subspan(offset); }
    constexpr __host__ auto subspan(const std::size_t offset, const std::size_t count) const
    {
      return m_span.subspan(offset, count);
    }

    buffer(const buffer&) = delete;
    buffer& operator=(const buffer&) = delete;
  };
} // namespace Allen
