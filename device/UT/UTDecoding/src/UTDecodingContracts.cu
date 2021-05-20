/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "UTCalculateNumberOfHits.cuh"

void ut_calculate_number_of_hits::version_checks::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context&) const
{
  auto const bank_version = first<Parameters::host_raw_bank_version_t>(arguments);
  const UTBoards ut_boards(constants.host_ut_boards.data());
  auto const geo_version = ut_boards.version;

  // Conditions to check
  bool bank_version_known = false;
  bool bank_version_matches_geo_version = true;

  const std::array<int, 3> known_bank_versions {-1, 3, 4};
  // map geometry versions to raw bank versions (int : raw bank, uint32_t : geo)
  std::unordered_map<int, uint32_t> geo_raw_bank_compatible_versions {{-1, 3}, {3, 3}, {4, 4}};

  for (const auto& known_bank_version : known_bank_versions)
    bank_version_known |= bank_version == known_bank_version;

  bank_version_matches_geo_version &= geo_raw_bank_compatible_versions[bank_version] == geo_version;

  require(bank_version_known, "Require that the encoded UT raw bank version is known");
  require(
    bank_version_matches_geo_version,
    "Require that the encoded UT raw bank version can be used with the UT geometry version parsed from the conditions "
    "database");
}
