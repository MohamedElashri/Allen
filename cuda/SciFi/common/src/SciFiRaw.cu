#include "SciFiRaw.cuh"

namespace SciFi {
  __device__ uint32_t getRawBankIndexOrderedByX(uint32_t index)
  {
    const uint k = index % 10; // Rawbank relative to zone
    // Reverse rawbank order when on the left side of a zone (because module order is M4–M0)
    const bool reverse_raw_bank_order = k < 5;
    // if reversed: index = offset(5 rb/zone) + reversed index within zone
    return reverse_raw_bank_order ? 5 * (index / 5) + (4 - index % 5) : index;
  }
} // namespace SciFi