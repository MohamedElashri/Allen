/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "HostSeedingXZValidator.h"
#include "PrepareTracks.h"

INSTANTIATE_ALGORITHM(host_seeding_XZ_validator::host_seeding_XZ_validator_t);
void host_seeding_XZ_validator::host_seeding_XZ_validator_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const Allen::Context& context) const
{
  const auto scifi_seedXZ_atomics = make_host_buffer<dev_offsets_scifi_seedsXZ_t>(arguments, context);
  const auto scifi_seedXZ_hit_number = make_host_buffer<dev_offsets_scifi_seedXZ_hit_number_t>(arguments, context);
  const auto scifi_seedsXZ = make_host_buffer<dev_scifi_seedsXZ_t>(arguments, context);
  const auto scifi_hits = make_host_buffer<dev_scifi_hits_t>(arguments, context);
  const auto scifi_hit_count = make_host_buffer<dev_scifi_hit_count_t>(arguments, context);
  const auto event_list = make_host_buffer<dev_event_list_t>(arguments, context);

  auto tracks = prepareSeedingTracksXZ(
    first<host_number_of_events_t>(arguments),
    scifi_seedXZ_atomics,
    scifi_seedXZ_hit_number,
    scifi_hits,
    scifi_hit_count,
    scifi_seedsXZ,
    event_list);

  auto& checker = runtime_options.checker_invoker->checker<TrackCheckerSeeding>(name(), m_root_output_filename);

  checker.accumulate(*first<host_mc_events_t>(arguments), tracks, event_list); // FIXME
}
