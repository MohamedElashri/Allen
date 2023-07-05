/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
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
    DEVICE_OUTPUT(dev_sv_atomics_t, unsigned) dev_sv_atomics;
    DEVICE_OUTPUT(dev_svs_trk1_idx_t, unsigned) dev_svs_trk1_idx;
    DEVICE_OUTPUT(dev_svs_trk2_idx_t, unsigned) dev_svs_trk2_idx;
    DEVICE_OUTPUT(dev_sv_poca_t, float) dev_sv_poca;
    PROPERTY(track_min_pt_both_t, "track_min_pt_both", "Minimum track pT required for both tracks.", float)
    track_min_pt_both;
    PROPERTY(track_min_pt_either_t, "track_min_pt_either", "Minimum track pT required for at least one track.", float)
    track_min_pt_either;
    PROPERTY(track_min_ipchi2_both_t, "track_min_ipchi2_both", "Minimum track IP chi2 required for both tracks.", float)
    track_min_ipchi2_both;
    PROPERTY(
      track_min_ipchi2_either_t,
      "track_min_ipchi2_either",
      "Minimum track IP chi2 required for at least one tracks.",
      float)
    track_min_ipchi2_either;
    PROPERTY(track_min_ip_both_t, "track_min_ip_both", "Minimum track IP required for both tracks.", float)
    track_min_ip_both;
    PROPERTY(track_min_ip_either_t, "track_min_ip_either", "Minimum track IP required for at least one track.", float)
    track_min_ip_either;
    PROPERTY(track_max_chi2ndof_t, "track_max_chi2ndof", "max track chi2/ndof", float) track_max_chi2ndof;
    PROPERTY(sum_pt_min_t, "sum_pt_min", "Minimum sum of track pT.", float) sum_pt_min;
    PROPERTY(doca_max_t, "doca_max", "Maximum DOCA between tracks.", float) doca_max;
    PROPERTY(require_os_pair_t, "require_os_pair", "Require that tracks have opposite-sign charge.", bool)
    require_os_pair;
    PROPERTY(require_same_pv_t, "require_same_pv", "Require both tracks to be associated with the same PV.", bool)
    require_same_pv;
    PROPERTY(require_muon_t, "require_muon", "Require both tracks to be identified as muons.", bool) require_muon;
    PROPERTY(require_electron_t, "require_electron", "Require both tracks to be identified as electrons.", bool)
    require_electron;
    PROPERTY(require_lepton_t, "require_lepton", "Require both tracks to be identified as leptons.", bool)
    require_lepton;
    PROPERTY(max_assoc_ipchi2_t, "max_assoc_ipchi2", "maximum IP chi2 to associate to PV", float) max_assoc_ipchi2;
    PROPERTY(block_dim_prefilter_t, "block_dim_prefilter", "block dimensions for prefilter step", DeviceDimensions)
    block_dim_prefilter;
    PROPERTY(block_dim_filter_t, "block_dim_filter", "block dimensions for filter step", DeviceDimensions)
    block_dim_filter;
  };

  __global__ void prefilter_tracks(Parameters);

  __global__ void filter_tracks(Parameters);

  struct filter_tracks_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<track_min_pt_both_t> m_minpt_both {this, 200.0f};
    Property<track_min_pt_either_t> m_minpt_either {this, 200.0f};
    Property<track_min_ipchi2_both_t> m_minipchi2_both {this, 4.0f};
    Property<track_min_ipchi2_either_t> m_minipchi2_either {this, 4.0f};
    Property<track_min_ip_both_t> m_minip_both {this, 0.06f * Gaudi::Units::mm};
    Property<track_min_ip_either_t> m_minip_either {this, 0.06f * Gaudi::Units::mm};
    Property<track_max_chi2ndof_t> m_maxchi2ndof {this, 10.0f};
    Property<doca_max_t> m_maxdoca {this, 1.f * Gaudi::Units::mm};
    Property<sum_pt_min_t> m_minsumpt {this, 400.0f};
    Property<require_os_pair_t> m_require_os_pair {this, false};
    Property<require_same_pv_t> m_require_same_pv {this, true};
    Property<require_muon_t> m_require_muon {this, false};
    Property<require_electron_t> m_require_electron {this, false};
    Property<require_lepton_t> m_require_lepton {this, false};
    Property<max_assoc_ipchi2_t> m_maxassocipchi2 {this, 16.0f};
    Property<block_dim_prefilter_t> m_block_dim_prefilter {this, {{256, 1, 1}}};
    Property<block_dim_filter_t> m_block_dim_filter {this, {{16, 16, 1}}};
  };

} // namespace FilterTracks
