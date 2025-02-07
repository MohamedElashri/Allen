/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "HeavyIonEventLine.cuh"

INSTANTIATE_LINE(heavy_ion_event_line::heavy_ion_event_line_t, heavy_ion_event_line::Parameters)

__device__ std::tuple<unsigned>
heavy_ion_event_line::heavy_ion_event_line_t::get_input(const Parameters&, const unsigned event_number, const unsigned)
{
  return std::forward_as_tuple(event_number);
}

__device__ bool heavy_ion_event_line::heavy_ion_event_line_t::select(
  const Parameters& parameters,
  const DeviceProperties& properties,
  std::tuple<unsigned> input)
{
  const auto event_number = std::get<0>(input);
  // Count VELO tracks
  int n_velo_tracks_PbPb = 0;
  int n_velo_tracks_SMOG = 0;
  const auto velo_tracks = parameters.dev_velo_tracks[event_number];
  const auto velo_states = parameters.dev_velo_states[event_number];
  for (unsigned i_track = 0; i_track < velo_tracks.size(); i_track++) {
    const auto velo_track = velo_tracks.track(i_track);
    const auto velo_state = velo_track.state(velo_states);
    if (velo_state.z() < properties.PbPb_SMOG_z_separation)
      n_velo_tracks_SMOG++;
    else
      n_velo_tracks_PbPb++;
  }

  // Count long tracks.
  const auto long_track_particles = static_cast<const Allen::Views::Physics::BasicParticles>(
    parameters.dev_long_track_particle_container[0].container(event_number));
  const int n_long_tracks = long_track_particles.size();

  // Count PVs
  int n_pvs_PbPb = 0;
  int n_pvs_SMOG = 0;
  Allen::device::span<PV::Vertex const> pvs {parameters.dev_pvs + event_number * PV::max_number_vertices,
                                             parameters.dev_number_of_pvs[event_number]};
  for (unsigned i_vrt = 0; i_vrt < pvs.size(); i_vrt++) {
    const auto pv = pvs[i_vrt];
    if (pv.position.z < properties.PbPb_SMOG_z_separation)
      n_pvs_SMOG++;
    else
      n_pvs_PbPb++;
  }

  // Get total ECAL energy.
  const float ecal_adc = parameters.dev_total_ecal_e[event_number];

  bool dec = n_velo_tracks_PbPb >= properties.min_velo_tracks_PbPb;
  dec &= n_velo_tracks_PbPb <= properties.max_velo_tracks_PbPb || properties.max_velo_tracks_PbPb < 0;
  dec &= n_velo_tracks_SMOG >= properties.min_velo_tracks_SMOG;
  dec &= n_velo_tracks_SMOG <= properties.max_velo_tracks_SMOG || properties.max_velo_tracks_SMOG < 0;

  dec &= n_pvs_PbPb >= properties.min_pvs_PbPb;
  dec &= n_pvs_PbPb <= properties.max_pvs_PbPb || properties.max_pvs_PbPb < 0;
  dec &= n_pvs_SMOG >= properties.min_pvs_SMOG;
  dec &= n_pvs_SMOG <= properties.max_pvs_SMOG || properties.max_pvs_SMOG < 0;

  dec &= ecal_adc >= properties.min_ecal_e;
  dec &= ecal_adc <= properties.max_ecal_e || properties.max_ecal_e < 0;

  dec &= n_long_tracks >= properties.min_long_tracks;
  dec &= n_long_tracks <= properties.max_long_tracks || properties.max_long_tracks < 0;

  return dec;
}
