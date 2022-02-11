/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <catch2/catch.hpp>
#include <HostPrefixSum.h>
#include <vector>
#include <numeric>

TEST_CASE("unit_tests.host_prefix_sum", "[HostPrefixSum]")
{
  std::vector<unsigned> v(1000);
  std::iota(std::begin(v), std::end(v), 1);

  // Do prefix sum with vectors
  std::vector<unsigned> output_v(v.size());
  output_v[0] = 0;
  std::partial_sum(v.begin(), v.end(), output_v.begin());
  const unsigned expected_sum = output_v.back();

  // Use host_prefix_sum_impl
  unsigned sum;
  host_prefix_sum::host_prefix_sum_impl(v.data(), v.size(), &sum);

  REQUIRE(sum == expected_sum);
  REQUIRE([&]() {
    for (size_t i = 0; i < v.size(); ++i) {
      if (v[i] != output_v[i]) {
        return false;
      }
    }
    return true;
  }());
}
