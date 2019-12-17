#include <gsl/gsl>

size_t add_raw_bank(
  unsigned char const type,
  unsigned char const version,
  short const sourceID,
  gsl::span<char const> fragment,
  char* buffer);
