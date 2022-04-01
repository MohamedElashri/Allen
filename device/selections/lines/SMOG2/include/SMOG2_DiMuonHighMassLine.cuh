/*****************************************************************************\
 * (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "TwoTrackLine.cuh"

namespace SMOG2_dimuon_highmass_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    HOST_OUTPUT(host_selected_events_size_t, unsigned) host_selected_events_size;

    DEVICE_INPUT(dev_odin_raw_input_t, char) dev_odin_raw_input;
    DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned) dev_odin_raw_input_offsets;
    DEVICE_INPUT(dev_mep_layout_t, unsigned) dev_mep_layout;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    DEVICE_OUTPUT(dev_decisions_t, bool) dev_decisions;
    DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned) dev_decisions_offsets;
    DEVICE_OUTPUT(dev_selected_events_size_t, unsigned) dev_selected_events_size;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_particle_container_ptr_t,
      DEPENDENCIES(dev_particle_container_t),
      Allen::IMultiEventContainer*)
    dev_particle_container_ptr;

    MASK_INPUT(dev_event_list_t) dev_event_list;
    MASK_OUTPUT(dev_selected_events_t) dev_selected_events;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string) pre_scaler_hash_string;
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string) post_scaler_hash_string;

    // SMOG2_DiMuonHighMass
    PROPERTY(maxTrackChi2Ndf_t, "minTrackChi2Ndf", "max track fit Chi2ndf", float) maxTrackChi2Ndf;
    PROPERTY(minTrackPt_t, "minTrackPt", "min track transverse momentum", float) minTrackPt;
    PROPERTY(minTrackP_t, "minTrackP", "min track momentum", float) minTrackP;
    PROPERTY(minMass_t, "minMass", "min invariant mass for track combination", float) minMass;
    PROPERTY(maxDoca_t, "maxDoca", "max distance of closest approach", float) maxDoca;
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "Max vertex chi2", float) maxVertexChi2;
    PROPERTY(minZ_t, "minZ", "minimum vertex z", float) minZ;
    PROPERTY(maxZ_t, "maxZ", "maximum vertex z", float) maxZ;
    PROPERTY(CombCharge_t, "HighMassCombCharge", "Charge of the combination", int) CombCharge;
  };

  struct SMOG2_dimuon_highmass_line_t : public SelectionAlgorithm,
                                        Parameters,
                                        TwoTrackLine<SMOG2_dimuon_highmass_line_t, Parameters> {
    __device__ static bool select(const Parameters&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<maxTrackChi2Ndf_t> m_maxTrackChi2Ndf {this, 3.f};
    Property<minTrackPt_t> m_minTrackPt {this, 500.f * Gaudi::Units::MeV};
    Property<minTrackP_t> m_minTrackP {this, 3000.f * Gaudi::Units::MeV};
    Property<minMass_t> m_minMass {this, 2700.f * Gaudi::Units::MeV};
    Property<CombCharge_t> m_CombCharge {this, 0};
    Property<maxDoca_t> m_maxDoca {this, 0.5f * Gaudi::Units::mm};
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 25.0f};
    Property<minZ_t> m_minZ {this, -550.f * Gaudi::Units::mm};
    Property<maxZ_t> m_maxZ {this, -300.f * Gaudi::Units::mm};
  };
} // namespace SMOG2_dimuon_highmass_line
