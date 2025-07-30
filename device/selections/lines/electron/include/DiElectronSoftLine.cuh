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
  };

  struct di_electron_soft_line_t : public SelectionAlgorithm,
                                   Parameters,
                                   CompositeParticleLine<di_electron_soft_line_t, Parameters> {

    struct DeviceProperties {
      float DESoftM0;
      float DESoftM1;
      float DESoftM2;
      float DESoftMinIP;
      float DESoftMinRho2;
      float DESoftMaxDOCA;
      float DESoftMaxIPDZ;
      float DESoftMinZ;
      float DESoftMaxZ;
      float DESoftGhost;
      bool OppositeSign;
      DeviceProperties(const di_electron_soft_line_t& algo, const Allen::Context&) :
        DESoftM0(algo.m_DESoftM0), DESoftM1(algo.m_DESoftM1), DESoftM2(algo.m_DESoftM2),
        DESoftMinIP(algo.m_DESoftMinIP), DESoftMinRho2(algo.m_DESoftMinRho2), DESoftMaxDOCA(algo.m_DESoftMaxDOCA),
        DESoftMaxIPDZ(algo.m_DESoftMaxIPDZ), DESoftMinZ(algo.m_DESoftMinZ), DESoftMaxZ(algo.m_DESoftMaxZ),
        DESoftGhost(algo.m_DESoftGhost), OppositeSign(algo.m_opposite_sign)
      {}
    };

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
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const bool, const float, const float>);

    __device__ static std::tuple<const Allen::Views::Physics::CompositeParticle, const bool, const float, const float>
    get_input(const Parameters&, const unsigned, const unsigned i);

    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const bool, const float, const float> input,
      unsigned index,
      bool sel);

  private:
    Allen::Property<float> m_DESoftM0 {this, "DESoftM0", 483.f, "lower m(pipi) for KS->pipi veto"};
    Allen::Property<float> m_DESoftM1 {this, "DESoftM1", 513.f, "higher m(pipi) for KS->pipi veto"};
    Allen::Property<float> m_DESoftM2 {this, "DESoftM2", 800.f, "upper m(ee)"};
    Allen::Property<float> m_DESoftMinIP {this, "DESoftMinIP", 1.45f, "min(IP) of the electrons"};
    Allen::Property<float> m_DESoftMinRho2 {this, "DESoftMinRho2", 9.1f, "minimum transverse distance to the beampipe"};
    Allen::Property<float> m_DESoftMaxDOCA {this, "DESoftMaxDOCA", 0.096f, "max DOCA between electrons"};
    Allen::Property<float> m_DESoftMaxIPDZ {this, "DESoftMaxIPDZ", 0.0024f, "DESoftMaxIPDZ description"};
    Allen::Property<float> m_DESoftMinZ {this, "DESoftMinZ", -375.f, "min z"};
    Allen::Property<float> m_DESoftMaxZ {this, "DESoftMaxZ", 635.f, "max z"};
    Allen::Property<float> m_DESoftGhost {this,
                                          "DESoftGhost",
                                          4.e-06f,
                                          "min sin2 of angle between electrons (ghost removal)"};
    Allen::Property<bool> m_opposite_sign {this, "OppositeSign", true, "Selects opposite sign dielectron combinations"};
  };
} // namespace di_electron_soft_line
