#pragma once

#include <vector>
#include <gsl-lite.hpp>

namespace EB {

  namespace detail {
    template<typename T>
    size_t padded_size(uint16_t nf)
    {
      auto p32 = sizeof(int32_t) / sizeof(T);
      return (nf % p32) == 0 ? nf : (nf / p32 + 1) * p32;
    }

    template<typename T>
    gsl::span<T> make_span(uint16_t nf, char const*& d)
    {
      gsl::span<T> s {const_cast<T*>(reinterpret_cast<T const*>(d)), padded_size<T>(nf)};
      d += s.size_bytes();
      return s;
    }

    template<typename T>
    void resize(uint16_t nf, std::vector<T>& cont, gsl::span<T>& view)
    {
      auto size = padded_size<T>(nf);
      cont.resize(size);
      cont.assign(size, 0);
      view = gsl::span<T> {&cont[0], size};
    }
  } // namespace detail

  struct Header {

    Header() = default;

    Header(uint16_t pf, uint16_t nb) : n_blocks {nb}, packing_factor {pf}
    {
      detail::resize(n_blocks, m_source_ids, source_ids);
      detail::resize(n_blocks, m_versions, versions);
      detail::resize(n_blocks, m_offsets, offsets);
    }

    Header(char const* data)
    {
      auto set = [&data](auto& t) {
        using t_t = std::remove_reference_t<decltype(t)>;
        t = *reinterpret_cast<t_t const*>(data);
        data += sizeof(t_t);
      };
      set(n_blocks);
      set(packing_factor);
      set(reserved);
      set(mep_size);
      source_ids = detail::make_span<uint16_t>(n_blocks, data);
      versions = detail::make_span<uint16_t>(n_blocks, data);
      offsets = detail::make_span<uint32_t>(n_blocks, data);
    }

    uint16_t n_blocks = 0;
    uint16_t packing_factor = 0;
    uint32_t reserved = 0;
    uint64_t mep_size = 0;

    gsl::span<uint16_t> source_ids;
    gsl::span<uint16_t> versions;
    gsl::span<uint32_t> offsets;

    static uint32_t base_size()
    {
      return sizeof(n_blocks) + sizeof(packing_factor) + sizeof(reserved) + sizeof(mep_size);
    }

    static uint32_t header_size(uint16_t nb)
    {
      using detail::padded_size;
      return (
        base_size() + +padded_size<decltype(source_ids)::value_type>(nb) * sizeof(decltype(source_ids)::value_type) +
        padded_size<decltype(versions)::value_type>(nb) * sizeof(decltype(versions)::value_type) +
        padded_size<decltype(offsets)::value_type>(nb) * sizeof(decltype(offsets)::value_type));
    }

  private:
    std::vector<uint16_t> m_source_ids;
    std::vector<uint16_t> m_versions;
    std::vector<uint32_t> m_offsets;
  };

  struct BlockHeader {

    BlockHeader() = default;

    BlockHeader(uint64_t evid, uint16_t nf) : event_id {evid}, n_frag {nf}
    {
      detail::resize(n_frag, m_types, types);
      detail::resize(n_frag, m_sizes, sizes);
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
      types = detail::make_span<unsigned char>(n_frag, data);
      sizes = detail::make_span<uint16_t>(n_frag, data);
    }

    uint64_t event_id = 0;
    uint16_t n_frag = 0;
    uint16_t reserved = 0;
    uint32_t block_size = 0;
    gsl::span<unsigned char> types;
    gsl::span<uint16_t> sizes;

    static uint32_t header_size(uint16_t nf)
    {
      using detail::padded_size;
      return (
        sizeof(event_id) + sizeof(n_frag) + sizeof(reserved) + sizeof(block_size) +
        +padded_size<decltype(types)::value_type>(nf) * sizeof(decltype(types)::value_type) +
        padded_size<decltype(sizes)::value_type>(nf) * sizeof(decltype(sizes)::value_type));
    }

  private:
    std::vector<unsigned char> m_types;
    std::vector<uint16_t> m_sizes;
  };
} // namespace EB
