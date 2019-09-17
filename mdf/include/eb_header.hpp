#pragma once

#include <vector>
#include <gsl-lite.hpp>

namespace EB {
struct Header {

  unsigned short source_id = 0;
  unsigned short version = 0;

};

struct BlockHeader {

  BlockHeader() = default;

  void init(uint64_t evid, uint16_t nf)
  {
    event_id = evid;
    n_frag = nf;
    block_size = sizeof(event_id) + sizeof(n_frag) + sizeof(reserved)
      + types.size() * sizeof(decltype(types)::value_type)
      + sizes.size() * sizeof(decltype(sizes)::value_type);
    resize(types);
    resize(sizes);
  };

  uint64_t event_id = 0;
  uint16_t n_frag = 0;
  uint16_t reserved = 0;
  uint32_t block_size;
  std::vector<unsigned char> types;
  std::vector<unsigned short> sizes;

  uint32_t header_size() const {
    return (sizeof(event_id) + sizeof(n_frag) + sizeof(reserved) + sizeof(block_size) +
            types.size() + sizes.size());
  }

private:

  template <typename T>
  void resize(std::vector<T>& cont)
  {
    auto p32 = sizeof(int32_t) / sizeof(T);
    auto size = (n_frag % p32) == 0 ? n_frag : (n_frag / p32 + 1) * p32;
    cont.resize(size);
    cont.assign(size, 0);
  }

};
}
