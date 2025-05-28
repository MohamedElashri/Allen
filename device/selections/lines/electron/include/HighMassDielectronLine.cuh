/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "CompositeParticleLine.cuh"
#include "ROOTService.h"
#include <ROOTHeaders.h>

#include "AllenMonitoring.h"

namespace highmass_dielectron_line {
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
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    // Outputs for ROOT tupling
    DEVICE_OUTPUT(mass_t, float) mass;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct highmass_dielectron_line_t : public SelectionAlgorithm,
                                      Parameters,
                                      CompositeParticleLine<highmass_dielectron_line_t, Parameters> {
    struct DeviceProperties {
      float minTrackP;
      float minTrackPt;
      float maxTrackEta;
      float minMass;
      float maxMass;
      float maxDoca;
      float minZ;
      bool oppositeSign;
      Allen::Monitoring::Histogram<>::DeviceType histogram_dielectron_Z_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_dielectron_upsilon_mass;
      DeviceProperties(const highmass_dielectron_line_t& algo, const Allen::Context& ctx) :
        minTrackP(algo.m_minTrackP), minTrackPt(algo.m_minTrackPt), maxTrackEta(algo.m_maxTrackEta),
        minMass(algo.m_minMass), maxMass(algo.m_maxMass), maxDoca(algo.m_maxDoca), minZ(algo.m_MinZ),
        oppositeSign(algo.m_only_select_opposite_sign),
        histogram_dielectron_Z_mass(algo.m_histogram_dielectron_Z_mass.data(ctx)),
        histogram_dielectron_upsilon_mass(algo.m_histogram_dielectron_upsilon_mass.data(ctx))
      {}
    };

    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<
        const Allen::Views::Physics::CompositeParticle,
        const bool,
        const bool,
        const float,
        const float,
        const float>);

    __device__ static std::tuple<
      const Allen::Views::Physics::CompositeParticle,
      const bool,
      const bool,
      const float,
      const float,
      const float>
    get_input(const Parameters&, const unsigned, const unsigned);

    __device__ static void monitor(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<
        const Allen::Views::Physics::CompositeParticle,
        const bool,
        const bool,
        const float,
        const float,
        const float>,
      unsigned,
      bool);

    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<
        const Allen::Views::Physics::CompositeParticle,
        const bool,
        const bool,
        const float,
        const float,
        const float>,
      unsigned,
      bool);

  private:
    // Low-mass no-IP dielectron selections.
    Allen::Property<float> m_minTrackP {this,
                                        "minTrackP",
                                        14.f * Gaudi::Units::GeV,
                                        "Minimal momentum for both daughters "};
    Allen::Property<float> m_minTrackPt {this, "minTrackPt", 1.5f * Gaudi::Units::GeV, "Minimal pT for both daughters"};
    Allen::Property<float> m_maxTrackEta {this, "maxTrackEta", 5.0, "Maximal ETA for both daughters"};
    Allen::Property<float> m_minMass {this, "minMass", 8.0f * Gaudi::Units::GeV, "Min mass of the composite"};
    Allen::Property<float> m_maxMass {this, "maxMass", 140.f * Gaudi::Units::GeV, "Max mass of the composite"};
    Allen::Property<float> m_maxDoca {this, "maxDoca", .2f * Gaudi::Units::mm, "maxDoca description"};
    Allen::Property<float> m_MinZ {this, "MinZ", -330.f * Gaudi::Units::mm, "Min z dielectron coordinate"};
    Allen::Property<bool> m_only_select_opposite_sign {this,
                                                       "OppositeSign",
                                                       true,
                                                       "Selects opposite sign dimuon combinations"};

    Allen::Monitoring::Histogram<> m_histogram_dielectron_Z_mass {this,
                                                                  "dielectron_Z_mass_counts",
                                                                  "dielectron masses w/brem (Z)",
                                                                  {100u, 60000.f, 120000.f}};
    Allen::Monitoring::Histogram<> m_histogram_dielectron_upsilon_mass {this,
                                                                        "dielectron_upsilon_mass_counts_ss",
                                                                        "dielectron masses w/brem (Upsilon)",
                                                                        {100u, 8000.f, 11500.f}};

    using monitoring_types = std::tuple<mass_t, evtNo_t, runNo_t>;
  };
} // namespace highmass_dielectron_line
