/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "TwoTrackLine.cuh"
#include "ParticleTypes.cuh"

namespace two_track_mva_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    DEVICE_INPUT(dev_two_track_mva_evaluation_t, float) dev_two_track_mva_evaluation;
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

    PROPERTY(minMVA_t, "minMVA", "Minimum passing MVA response.", float) minMVA;
    PROPERTY(minPt_t, "minPt", "Minimum track pT in MeV.", float) minPt;
    PROPERTY(minSVpt_t, "minSVpt", "Minimum SV pT in MeV.", float) minSVpt;
    PROPERTY(minEta_t, "minEta", "Minimum PV-SV eta.", float) minEta;
    PROPERTY(maxEta_t, "maxEta", "Maximum PV-SV eta.", float) maxEta;
    PROPERTY(minMcor_t, "minMcor", "Minimum corrected mass in MeV", float) minMcor;
    PROPERTY(maxSVchi2_t, "maxSVchi2", "Maximum SV chi2", float) maxSVchi2;
    PROPERTY(maxDOCA_t, "maxDOCA", "Maximum DOCA between two tracks", float) maxDOCA;
    PROPERTY(minipchi2_t, "minipchi2", "minimum ipchi2 of the tracks", float) minipchi2;
    PROPERTY(minZ_t, "minZ", "minimum vertex z coordinate", float) minZ;
  };

  struct two_track_mva_line_t : public SelectionAlgorithm, Parameters, TwoTrackLine<two_track_mva_line_t, Parameters> {
    __device__ static std::tuple<const Allen::Views::Physics::CompositeParticle, const float>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);

    __device__ static bool select(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};

    Property<minMVA_t> m_minMVA {this, 0.9569f}; // tuned to about 660 kHz (modulo GEC)
    Property<minPt_t> m_minPt {this, 200.f * Gaudi::Units::MeV};
    Property<minSVpt_t> m_minSVpt {this, 1000.f * Gaudi::Units::MeV};
    Property<minEta_t> m_minEta {this, 2.f};
    Property<maxEta_t> m_maxEta {this, 5.f};
    Property<minMcor_t> m_minMcor {this, 1000.f};
    Property<maxSVchi2_t> m_maxSVchi2 {this, 20.f};
    Property<maxDOCA_t> m_maxDOCA {this, 0.2f};
    Property<minipchi2_t> m_minipchi2 {this, 4.f}; // this is probably a noop, but better safe than sorry
    Property<minZ_t> m_minZ {this, -300.f * Gaudi::Units::mm};
  };

} // namespace two_track_mva_line
