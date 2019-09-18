#pragma once

#include <vector>
#include <gsl-lite.hpp>

namespace EB {

  template <typename T>
  size_t padded_size(uint16_t nf) {
    auto p32 = sizeof(int32_t) / sizeof(T);
    return (nf % p32) == 0 ? nf : (nf / p32 + 1) * p32;
  }

  struct Header {

    uint16_t source_id = 0;
    uint16_t version = 0;

  };

  struct BlockHeader {

    BlockHeader() = default;

    BlockHeader(uint64_t evid, uint16_t nf)
      : event_id{evid}, n_frag{nf}
    {
      resize(types, m_types);
      resize(sizes, m_sizes);
    };

    BlockHeader(char const* data)
    {
      auto set = [&data](auto& t) {
                   using t_t = std::remove_reference_t<decltype(t)>;
                   t = *reinterpret_cast<t_t const*>(data);
                   data += sizeof(t_t);
                 };
      set(event_id);
      set(n_frag);
      set(reserved);
      set(block_size);
      types = make_span<unsigned char>(data);
      data += types.size_bytes();
      sizes = make_span<uint16_t>(data);
    }

    uint64_t event_id = 0;
    uint16_t n_frag = 0;
    uint16_t reserved = 0;
    uint32_t block_size = 0;
    gsl::span<unsigned char> types;
    gsl::span<uint16_t> sizes;

    static uint32_t header_size(uint16_t nf) {
      return (sizeof(event_id) + sizeof(n_frag) + sizeof(reserved) + sizeof(block_size) +
              + padded_size<decltype(types)::value_type>(nf) * sizeof(decltype(types)::value_type)
              + padded_size<decltype(sizes)::value_type>(nf) * sizeof(decltype(sizes)::value_type));
    }

  private:

    template<typename T>
    gsl::span<T> make_span(char const* d) {
      return {const_cast<T*>(reinterpret_cast<T const*>(d)), padded_size<T>(n_frag)};
    }

    template <typename T>
    void resize(gsl::span<T>& view, std::vector<T>& cont)
    {
      auto size = padded_size<T>(n_frag);
      cont.resize(size);
      cont.assign(size, 0);
      view = gsl::span<T>{&cont[0], size};
    }

    std::vector<unsigned char> m_types;
    std::vector<uint16_t> m_sizes;

  };
}
