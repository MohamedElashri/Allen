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
#pragma once

#include "ParKalmanDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "ParKalmanFittedTrack.cuh"
#include "VertexDefinitions.cuh"
#include "PV_Definitions.cuh"
#include "SciFiConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "VeloConsolidated.cuh"
#include "AssociateConsolidated.cuh"
#include "States.cuh"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"

namespace FilterTracks {

  // TODO: The chi2/ndof cuts are for alignment with Moore. These cuts
  // should ultimately be defined in a selection. The fact that this
  // works out so neatly for now is coincidental.
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_tracks_t, unsigned) host_number_of_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    // TODO: Choose a better name for this, because these don't need to be long
    // tracks.
    DEVICE_INPUT(dev_long_track_particles_t, Allen::Views::Physics::MultiEventBasicParticles)
    dev_long_track_particles;
    DEVICE_OUTPUT(dev_track_prefilter_result_t, bool) dev_track_prefilter_result;
    DEVICE_OUTPUT(dev_sv_offsets_t, unsigned) dev_sv_offsets;
    HOST_OUTPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_OUTPUT(dev_svs_trk1_idx_t, unsigned) dev_svs_trk1_idx;
    DEVICE_OUTPUT(dev_svs_trk2_idx_t, unsigned) dev_svs_trk2_idx;
    DEVICE_OUTPUT(dev_sv_poca_t, float) dev_sv_poca;
  };

  __global__ void prefilter_tracks(
    Parameters,
    const float track_min_pt_both,
    const float track_min_ipchi2_both,
    const float track_max_chi2ndof,
    const float track_min_ip_both,
    const bool require_muon,
    const bool require_electron,
    const bool require_lepton);

  __global__ void filter_tracks(
    Parameters,
    const bool require_os_pair,
    const bool require_same_pv,
    const float max_assoc_ipchi2,
    const float track_min_pt_either,
    const float track_min_ip_either,
    const float track_min_ipchi2_either,
    const float sum_pt_min,
    const float doca_max);

  struct filter_tracks_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<float> m_minpt_both {this,
                                         "track_min_pt_both",
                                         200.0f,
                                         "Minimum track pT required for both tracks."};
    Allen::Property<float> m_minpt_either {this,
                                           "track_min_pt_either",
                                           200.0f,
                                           "Minimum track pT required for at least one track."};
    Allen::Property<float> m_minipchi2_both {this,
                                             "track_min_ipchi2_both",
                                             4.0f,
                                             "Minimum track IP chi2 required for both tracks."};
    Allen::Property<float> m_minipchi2_either {this,
                                               "track_min_ipchi2_either",
                                               4.0f,
                                               "Minimum track IP chi2 required for at least one tracks."};
    Allen::Property<float> m_minip_both {this,
                                         "track_min_ip_both",
                                         0.06f * Allen::Units::mm,
                                         "Minimum track IP required for both tracks."};
    Allen::Property<float> m_minip_either {this,
                                           "track_min_ip_either",
                                           0.06f * Allen::Units::mm,
                                           "Minimum track IP required for at least one track."};
    Allen::Property<float> m_maxchi2ndof {this, "track_max_chi2ndof", 10.0f, "max track chi2/ndof"};
    Allen::Property<float> m_maxdoca {this, "doca_max", 1.f * Allen::Units::mm, "Maximum DOCA between tracks."};
    Allen::Property<float> m_minsumpt {this, "sum_pt_min", 400.0f * Allen::Units::MeV, "Minimum sum of track pT."};
    Allen::Property<bool> m_require_os_pair {this,
                                             "require_os_pair",
                                             false,
                                             "Require that tracks have opposite-sign charge."};
    Allen::Property<bool> m_require_same_pv {this,
                                             "require_same_pv",
                                             true,
                                             "Require both tracks to be associated with the same PV."};
    Allen::Property<bool> m_require_muon {this,
                                          "require_muon",
                                          false,
                                          "Require both tracks to be identified as muons."};
    Allen::Property<bool> m_require_electron {this,
                                              "require_electron",
                                              false,
                                              "Require both tracks to be identified as electrons."};
    Allen::Property<bool> m_require_lepton {this,
                                            "require_lepton",
                                            false,
                                            "Require both tracks to be identified as leptons."};
    Allen::Property<float> m_maxassocipchi2 {this, "max_assoc_ipchi2", 16.0f, "maximum IP chi2 to associate to PV"};
    Allen::Property<dim3> m_block_dim_prefilter {this,
                                                 "block_dim_prefilter",
                                                 {256, 1, 1},
                                                 "block dimensions for prefilter step"};
    Allen::Property<dim3> m_block_dim_filter {this,
                                              "block_dim_filter",
                                              {16, 16, 1},
                                              "block dimensions for filter step"};
  };

} // namespace FilterTracks
