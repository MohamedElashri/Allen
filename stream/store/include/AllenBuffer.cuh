#pragma once

#include <MemoryManager.cuh>
#include <gsl/gsl>

namespace Allen {
  template<typename S, typename T>
  struct buffer {
  private:
    Allen::Store::memory_manager_t<S>& m_mem_manager;
    const std::string m_tag;
    gsl::span<T> m_span;

  public:
    __host__ buffer(Allen::Store::memory_manager_t<S>& mem_manager, const std::string& tag, size_t size) :
      m_mem_manager(mem_manager), m_tag(tag), m_span(reinterpret_cast<T*>(m_mem_manager.reserve(m_tag, size * sizeof(T))), size)
    {}
    
    __host__ ~buffer() { m_mem_manager.free(m_tag); }
    
    constexpr __host__ size_t size() const {
      return m_span.size();
    }

    constexpr __host__ size_t sizebytes() const {
      static_assert(std::is_same_v<S, Allen::Store::memory_manager_details::Host>);
      return m_span.sizebytes();
    }

    __host__ void resize(size_t size) {
      m_mem_manager.free(m_tag);
      m_span = gsl::span<T>{reinterpret_cast<T*>(m_mem_manager.reserve(m_tag, size * sizeof(T))), size};
    }
    
    __host__ gsl::span<T> to_span() { return m_span; }

    __host__ operator gsl::span<T>() { return m_span; }
    
    constexpr __host__ T& operator[](int i) {
      static_assert(std::is_same_v<S, Allen::Store::memory_manager_details::Host>);
      return m_span[i];
    }
    
    constexpr __host__ const T& operator[](int i) const {
      static_assert(std::is_same_v<S, Allen::Store::memory_manager_details::Host>);
      return m_span[i];
    }

    buffer(const buffer&) = delete;
    buffer& operator=(const buffer&) = delete;
    buffer(buffer&&) = delete;
    buffer& operator=(buffer&&) = delete;
  };

  template<typename T>
  using host_buffer = buffer<Allen::Store::memory_manager_details::Host, T>;

  template<typename T>
  using device_buffer = buffer<Allen::Store::memory_manager_details::Device, T>;
} // namespace Allen
