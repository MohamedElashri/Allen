/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "HostSeedingValidator.h"
#include "PrepareTracks.h"

INSTANTIATE_ALGORITHM(host_seeding_validator::host_seeding_validator_t);
void host_seeding_validator::host_seeding_validator_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const Allen::Context& context) const
{
  const auto scifi_seed_atomics = make_host_buffer<dev_offsets_scifi_seeds_t>(arguments, context);
  const auto scifi_seed_hit_number = make_host_buffer<dev_offsets_scifi_seed_hit_number_t>(arguments, context);
  const auto scifi_seed_hits = make_host_buffer<dev_scifi_hits_t>(arguments, context);
  const auto scifi_seeds = make_host_buffer<dev_scifi_seeds_t>(arguments, context);
  const auto seeding_states = make_host_buffer<dev_seeding_states_t>(arguments, context);
  const auto event_list = make_host_buffer<dev_event_list_t>(arguments, context);

  auto tracks = prepareSeedingTracks(
    first<host_number_of_events_t>(arguments),
    scifi_seed_atomics,
    scifi_seed_hit_number,
    scifi_seed_hits,
    scifi_seeds,
    seeding_states,
    event_list);

  auto& checker =
    runtime_options.checker_invoker->checker<TrackCheckerSeeding>(name(), property<root_output_filename_t>());
  checker.accumulate(*first<host_mc_events_t>(arguments), tracks, event_list); // FIXME
}
