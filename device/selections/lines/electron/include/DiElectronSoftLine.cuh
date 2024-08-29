/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "CompositeParticleLine.cuh"
#include "ROOTService.h"
#include "MassDefinitions.h"

namespace di_electron_soft_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    // Kalman fitted tracks
    DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
    // ECAL
    DEVICE_INPUT(dev_track_isElectron_t, bool) dev_track_isElectron;
    DEVICE_INPUT(dev_brem_corrected_pt_t, float) dev_brem_corrected_pt;
    // Outputs
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;

    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    // Device outputs for monitoring
    DEVICE_OUTPUT(pipi_masses_t, float) pipi_masses;
    DEVICE_OUTPUT(ee_masses_t, float) ee_masses;
    DEVICE_OUTPUT(minip_t, float) minip;
    DEVICE_OUTPUT(sv_rho2_t, float) sv_rho2;
    DEVICE_OUTPUT(sv_z_t, float) sv_z;
    DEVICE_OUTPUT(ee_doca_t, float) ee_doca;
    DEVICE_OUTPUT(sv_ipperdz_t, float) sv_ipperdz;
    DEVICE_OUTPUT(ee_cloneang_t, float) ee_cloneang;
    DEVICE_OUTPUT(minpt_uncorr_t, float) minpt_uncorr;
    DEVICE_OUTPUT(sv_pt_t, float) sv_pt;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(DESoftM0_t, "DESoftM0", "lower m(pipi) for KS->pipi veto", float) DESoftM0;
    PROPERTY(DESoftM1_t, "DESoftM1", "higher m(pipi) for KS->pipi veto", float) DESoftM1;
    PROPERTY(DESoftM2_t, "DESoftM2", "upper m(ee)", float) DESoftM2;
    PROPERTY(DESoftMinIP_t, "DESoftMinIP", "min(IP) of the electrons", float) DESoftMinIP;
    PROPERTY(DESoftMinRho2_t, "DESoftMinRho2", "minimum transverse distance to the beampipe", float) DESoftMinRho2;
    PROPERTY(DESoftMinZ_t, "DESoftMinZ", "min z", float) DESoftMinZ;
    PROPERTY(DESoftMaxZ_t, "DESoftMaxZ", "max z", float) DESoftMaxZ;
    PROPERTY(DESoftMaxDOCA_t, "DESoftMaxDOCA", "max DOCA between electrons", float) DESoftMaxDOCA;
    PROPERTY(DESoftMaxIPDZ_t, "DESoftMaxIPDZ", "DESoftMaxIPDZ description", float) DESoftMaxIPDZ;
    PROPERTY(DESoftGhost_t, "DESoftGhost", "min sin2 of angle between electrons (ghost removal)", float) DESoftGhost;
    PROPERTY(OppositeSign_t, "OppositeSign", "Selects opposite sign dielectron combinations", bool) OppositeSign;
    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;
    PROPERTY(enable_tupling_t, "enable_tupling", "Enables monitoring ntuple", bool) enable_tupling;
  };

  struct di_electron_soft_line_t : public SelectionAlgorithm,
                                   Parameters,
                                   CompositeParticleLine<di_electron_soft_line_t, Parameters> {

    using monitoring_types = std::tuple<
      pipi_masses_t,
      ee_masses_t,
      minip_t,
      sv_rho2_t,
      sv_z_t,
      ee_doca_t,
      sv_ipperdz_t,
      ee_cloneang_t,
      minpt_uncorr_t,
      sv_pt_t>;

    __device__ static bool select(
      const Parameters&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const bool, const float, const float>);

    __device__ static std::tuple<const Allen::Views::Physics::CompositeParticle, const bool, const float, const float>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);

    __device__ static void fill_tuples(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const bool, const float, const float> input,
      unsigned index,
      bool sel);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<DESoftM0_t> m_DESoftM0 {this, 465.f};
    Property<DESoftM1_t> m_DESoftM1 {this, 530.f};
    Property<DESoftM2_t> m_DESoftM2 {this, 800.f};
    Property<DESoftMinIP_t> m_DESoftMinIP {this, 0.5f};
    Property<DESoftMinRho2_t> m_DESoftMinRho2 {this, 9.f};
    Property<DESoftMinZ_t> m_DESoftMinZ {this, -10.f};
    Property<DESoftMaxZ_t> m_DESoftMaxZ {this, 635.f};
    Property<DESoftMaxDOCA_t> m_DESoftMaxDOCA {this, 0.1f};
    Property<DESoftMaxIPDZ_t> m_DESoftMaxIPDZ {this, 0.02f};
    Property<DESoftGhost_t> m_DESoftGhost {this, 4.e-06f};
    Property<OppositeSign_t> m_opposite_sign {this, true};
    Property<enable_monitoring_t> m_enable_monitoring {this, true};
    Property<enable_tupling_t> m_enable_tupling {this, true};
  };
} // namespace di_electron_soft_line
