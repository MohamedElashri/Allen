/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "ConsolidateSciFiSeedingXZ.cuh"

INSTANTIATE_ALGORITHM(seed_xz_consolidate::seed_xz_consolidate_t);

void seed_xz_consolidate::seed_xz_consolidate_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  //  set_size<dev_seeding_qop_t>(arguments, first<host_number_of_reconstructed_seeding_tracksXZ_t>(arguments));
}

void seed_xz_consolidate::seed_xz_consolidate_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  global_function(seed_xz_consolidate)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments);
}

__global__ void seed_xz_consolidate::seed_xz_consolidate(seed_xz_consolidate::Parameters parameters)
{
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const unsigned total_number_of_hits = parameters.dev_scifi_hit_count[number_of_events];
  const SciFi::Seeding::TrackXZ* event_scifi_tracksXZ =
    parameters.dev_seeding_tracksXZ + event_number * SciFi::Constants::Nmax_seed_xz;
  SciFi::ConstHits scifi_hits {parameters.dev_scifi_hits, total_number_of_hits};
  //  SciFi::Consolidated::Tracks
}
