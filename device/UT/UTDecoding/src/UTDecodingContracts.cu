/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "UTCalculateNumberOfHits.cuh"

void ut_calculate_number_of_hits::version_checks::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context&) const
{
  auto const bank_version = first<Parameters::host_raw_bank_version_t>(arguments);

  // Condition to check
  bool bank_version_known = false;
  // TODO : how to get geo and numbering versions here?
  // bool bank_version_matches_geo_version = true;
  // bool bank_version_matches_numbering_version = true;

  const std::array<int, 3> known_bank_versions {-1, 3, 4};
  // map geometry versions to raw bank versions (first int : geo, second int : raw bank)
  // const std::unordered_map<int,int> geo_raw_bank_compatible_versions{{-1,3},{3,3},{4,4},{5,4}};
  //// same for the numbering scheme
  // const std::unordered_map<int,int> numbering_raw_bank_compatible_versions{{-1,3},{3,3},{4,4}};

  for (const auto& known_bank_version : known_bank_versions)
    bank_version_known |= bank_version == known_bank_version;

  // bank_version_matches_geo_version &= geo_raw_bank_compatible_versions[geo_version] == bank_version;
  // bank_version_matches_numbering_version &= geo_raw_bank_compatible_versions[numbering_version] == bank_version;

  require(bank_version_known, "Require that the encoded UT raw bank version is known");
  // require(bank_version_matches_geo_version, "Require that the encoded UT raw bank version can be used with the UT
  // geometry version parsed from the conditions database"); require(bank_version_matches_numbering_version, "Require
  // that the encoded UT raw bank version can be used with the UT numbering scheme parsed from the detector database");
}