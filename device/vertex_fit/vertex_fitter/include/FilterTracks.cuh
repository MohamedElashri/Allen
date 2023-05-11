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
    DEVICE_OUTPUT(dev_track_prefilter_result_t, float) dev_track_prefilter_result;
    DEVICE_OUTPUT(dev_sv_atomics_t, unsigned) dev_sv_atomics;
    DEVICE_OUTPUT(dev_svs_trk1_idx_t, unsigned) dev_svs_trk1_idx;
    DEVICE_OUTPUT(dev_svs_trk2_idx_t, unsigned) dev_svs_trk2_idx;
    DEVICE_OUTPUT(dev_sv_poca_t, float) dev_sv_poca;
    PROPERTY(track_min_pt_t, "track_min_pt", "minimum track pT", float) track_min_pt;
    PROPERTY(track_min_pt_low_ip_t, "track_min_pt_low_ip", "minimum track pT for low IP", float) track_min_pt_low_ip;
    PROPERTY(track_min_ipchi2_t, "track_min_ipchi2", "minimum track IP chi2", float) track_min_ipchi2;
    PROPERTY(track_min_high_ip_t, "track_min_high_ip", "minimum track high IP", float) track_min_high_ip;
    PROPERTY(track_min_low_ip_t, "track_min_low_ip", "minimum track low IP", float) track_min_low_ip;
    PROPERTY(track_muon_min_ipchi2_t, "track_muon_min_ipchi2", "minimum muon IP chi2", float) track_muon_min_ipchi2;
    PROPERTY(track_max_chi2ndof_t, "track_max_chi2ndof", "max track chi2/ndof", float) track_max_chi2ndof;
    PROPERTY(track_muon_max_chi2ndof_t, "track_muon_max_chi2ndof", "max muon chi2/ndof", float)
    track_muon_max_chi2ndof;
    PROPERTY(max_assoc_ipchi2_t, "max_assoc_ipchi2", "maximum IP chi2 to associate to PV", float) max_assoc_ipchi2;
    PROPERTY(L_p_MIPCHI2_min_t, "L_p_MIPCHI2_min", "proton min ip chi^2 for Lambda LL", float) L_p_MIPCHI2_min;
    PROPERTY(L_pi_MIPCHI2_min_t, "L_pi_MIPCHI2_min", "pion min ip chi^2 for Lambda LL", float) L_pi_MIPCHI2_min;
    PROPERTY(L_p_MIP_min_t, "L_p_MIP_min", "proton min ip for Lambda LL", float) L_p_MIP_min;
    PROPERTY(L_pi_MIP_min_t, "L_pi_MIP_min", "pion min ip for Lambda LL", float) L_pi_MIP_min;
    PROPERTY(L_p_PT_min_t, "L_p_PT_min", "proton min pT for Lambda LL", float) L_p_PT_min;
    PROPERTY(L_pi_PT_min_t, "L_pi_PT_min", "pion min pT for Lambda LL", float) L_pi_PT_min;
    PROPERTY(L_DOCA_max_t, "L_DOCA_max", "max p,pi DOCA for Lambda LL", float) L_DOCA_max;
    PROPERTY(L_PT2_min_t, "L_PT2_min", "min pT of Lambda LL", float) L_PT2_min;
    PROPERTY(L_M_max_t, "L_M_max", "max mass for Lambda LL", float) L_M_max;
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
    Property<track_min_pt_t> m_minpt {this, 200.0f * Gaudi::Units::MeV};
    Property<track_min_pt_low_ip_t> m_minptlowip {this, 500.0f * Gaudi::Units::MeV};
    Property<track_min_ipchi2_t> m_minipchi2 {this, 4.0f};
    Property<track_min_high_ip_t> m_minhighip {this, 0.2f * Gaudi::Units::mm};
    Property<track_min_low_ip_t> m_minlowip {this, 0.06f * Gaudi::Units::mm};
    Property<track_muon_min_ipchi2_t> m_minmuipchi2 {this, 4.0f};
    Property<track_max_chi2ndof_t> m_maxchi2ndof {this, 2.5f};
    Property<track_muon_max_chi2ndof_t> m_muonmaxchi2ndof {this, 100.f};
    Property<max_assoc_ipchi2_t> m_maxassocipchi2 {this, 16.0f};
    Property<L_p_MIPCHI2_min_t> m_L_p_MIPCHI2_min {this, 12.f};
    Property<L_pi_MIPCHI2_min_t> m_L_pi_MIPCHI2_min {this, 32.f};
    Property<L_p_MIP_min_t> m_L_p_MIP_min {this, 80.f * Gaudi::Units::um};
    Property<L_pi_MIP_min_t> m_L_pi_MIP_min {this, 200.f * Gaudi::Units::um};
    Property<L_p_PT_min_t> m_L_p_PT_min {this, 450.f * Gaudi::Units::MeV};
    Property<L_pi_PT_min_t> m_L_pi_PT_min {this, 80.f * Gaudi::Units::MeV};
    Property<L_DOCA_max_t> m_DOCA_max {this, 500.f * Gaudi::Units::um};
    Property<L_PT2_min_t> m_PT2_min {this, 500.f * 500.f * Gaudi::Units::MeV* Gaudi::Units::MeV};
    Property<L_M_max_t> m_M_max {this, 1140.f * Gaudi::Units::MeV};
    Property<block_dim_prefilter_t> m_block_dim_prefilter {this, {{256, 1, 1}}};
    Property<block_dim_filter_t> m_block_dim_filter {this, {{16, 16, 1}}};
  };

} // namespace FilterTracks