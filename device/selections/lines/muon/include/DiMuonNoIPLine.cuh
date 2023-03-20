/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "ParKalmanFilter.cuh"
#include "AlgorithmTypes.cuh"
#include "TwoTrackLine.cuh"
#include "ROOTService.h"

namespace di_muon_no_ip_line {
  struct Parameters {
    DEVICE_OUTPUT(dev_trk1Chi2_t, float) dev_trk1Chi2;
    DEVICE_OUTPUT(dev_trk2Chi2_t, float) dev_trk2Chi2;
    DEVICE_OUTPUT(dev_doca_t, float) dev_doca;
    DEVICE_OUTPUT(dev_trk1pt_t, float) dev_trk1pt;
    DEVICE_OUTPUT(dev_trk2pt_t, float) dev_trk2pt;
    DEVICE_OUTPUT(dev_p1_t, float) dev_p1;
    DEVICE_OUTPUT(dev_p2_t, float) dev_p2;
    DEVICE_OUTPUT(dev_vChi2_t, float) dev_vChi2;
    DEVICE_OUTPUT(dev_same_sign_t, bool) dev_same_sign;
    DEVICE_OUTPUT(dev_same_sign_on_t, bool) dev_same_sign_on;
    DEVICE_OUTPUT(dev_is_dimuon_t, bool) dev_is_dimuon;
    DEVICE_OUTPUT(dev_pt_t, float) dev_pt;
    DEVICE_OUTPUT(dev_eventNum_t, int16_t) dev_eventNum;

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(minTrackPtPROD_t, "minTrackPtPROD", "minTrackPtPROD description", float) minTrackPtPROD;
    PROPERTY(minTrackP_t, "minTrackP", "minTrackP description", float) minTrackP;
    PROPERTY(maxDoca_t, "maxDoca", "maxDoca description", float) maxDoca;
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "maxVertexChi2 description", float) maxVertexChi2;
    PROPERTY(maxTrChi2_t, "maxTrChi2", "maxTrChi2 description", float) maxTrChi2;
    PROPERTY(ss_on_t, "ss_on", "ss_on description", bool) ss_on;
    PROPERTY(minPt_t, "minPt", "minPt description", float) minPt;
    PROPERTY(minZ_t, "minZ", "minimum vertex z coordinate", float) minZ;

    PROPERTY(make_tuple_t, "make_tuple", "Make tuple for monitoring", bool) make_tuple;
  };

  struct di_muon_no_ip_line_t : public SelectionAlgorithm, Parameters, TwoTrackLine<di_muon_no_ip_line_t, Parameters> {
    using monitoring_types = std::tuple<
      dev_trk1Chi2_t,
      dev_trk2Chi2_t,
      dev_doca_t,
      dev_trk1pt_t,
      dev_trk2pt_t,
      dev_p1_t,
      dev_p2_t,
      dev_vChi2_t,
      dev_same_sign_t,
      dev_same_sign_on_t,
      dev_is_dimuon_t,
      dev_pt_t,
      dev_eventNum_t>;

    __device__ static bool select(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input);

    __device__ static void monitor(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<minTrackPtPROD_t> m_minTrackPtPROD {this,
                                                 1.f * Gaudi::Units::GeV* Gaudi::Units::GeV}; // run 2 value: 1.*GeV*GeV
    Property<minTrackP_t> m_minTrackP {this, 5000.f * Gaudi::Units::MeV};                     // run 2 value: 10000
    Property<maxDoca_t> m_maxDoca {this, .1f};                                                // run 2 value: 0.1
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 9.f};                                    // run 2 value: 9
    Property<maxTrChi2_t> m_maxTrChi2 {this, 3.f};                                            // run 2 value: 3
    Property<ss_on_t> m_ss_on {this, false};
    Property<minPt_t> m_minPt {this, 1.f * Gaudi::Units::GeV};
    Property<minZ_t> m_minZ {this, -341.f * Gaudi::Units::mm};

    // Switch to create monitoring tuple
    Property<make_tuple_t> m_make_tuple {this, false};
  };
} // namespace di_muon_no_ip_line
