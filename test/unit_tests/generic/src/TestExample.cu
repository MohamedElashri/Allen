/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#if __has_include(<catch2/catch.hpp>)
// Catch2 v2
#include <catch2/catch.hpp>
namespace Catch {
  using Detail::Approx;
}
#else
// Catch2 v3
#include <catch2/catch_approx.hpp>
#include <catch2/catch_template_test_macros.hpp>
#include <catch2/catch_test_macros.hpp>
#endif
TEST_CASE("unit_tests.testexample", "[TestExample]") { REQUIRE(true); }
