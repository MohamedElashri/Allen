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
#include "pv_beamline_calculate_denom.cuh"

INSTANTIATE_ALGORITHM(pv_beamline_calculate_denom::pv_beamline_calculate_denom_t)

void pv_beamline_calculate_denom::pv_beamline_calculate_denom_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_pvtracks_denom_t>(arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments));
}

void pv_beamline_calculate_denom::pv_beamline_calculate_denom_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  global_function(pv_beamline_calculate_denom)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments);
}

void pv_beamline_calculate_denom::pv_beamline_calculate_denom_t::update(const Constants& constants) const
{
  updateCommon(constants);
}
__global__ void pv_beamline_calculate_denom::pv_beamline_calculate_denom(Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const auto velo_tracks = parameters.dev_velo_tracks_view[event_number];

  const float* zseeds = parameters.dev_zpeaks + event_number * PV::max_number_vertices;
  const unsigned number_of_seeds = parameters.dev_number_of_zpeaks[event_number];

  const PVTrack* tracks = parameters.dev_pvtracks + velo_tracks.offset();
  float* pvtracks_denom = parameters.dev_pvtracks_denom + velo_tracks.offset();

  // Precalculate all track denoms
  for (unsigned i = threadIdx.x; i < velo_tracks.size(); i += blockDim.x) {
    auto track_denom = 0.f;
    const auto track = tracks[i];
    float tx_beam;
    float ty_beam;
    if (track.z > BeamlinePVConstants::Common::SMOG2_pp_separation) {
      tx_beam = dev_beamline.tx.x;
      ty_beam = dev_beamline.tx.y;
    }
    else {
      tx_beam = dev_beamline.tx_SMOG.x;
      ty_beam = dev_beamline.tx_SMOG.y;
    }
    for (unsigned j = 0; j < number_of_seeds; ++j) {

      const float2 seed_pos_xy {dev_beamline.pos.x + tx_beam * zseeds[j], dev_beamline.pos.y + ty_beam * zseeds[j]};

      const auto dz = zseeds[j] - track.z;
      const float2 res = track.x + track.tx * dz - seed_pos_xy;
      const auto chi2 = res.x * res.x * track.W_00 + res.y * res.y * track.W_11;
      track_denom += expf(chi2 * (-0.5f));
    }

    pvtracks_denom[i] = track_denom;
  }
}
