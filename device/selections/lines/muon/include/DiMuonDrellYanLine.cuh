/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "CompositeParticleLine.cuh"
#include "ROOTService.h"

#include "AllenMonitoring.h"

namespace di_muon_drell_yan_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
    DEVICE_INPUT(dev_chi2muon_t, float) dev_chi2muon;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);

    PROPERTY(minTrackP_t, "minTrackP", "Minimal momentum for both daughters ", float) minTrackP;
    PROPERTY(minTrackPt_t, "minTrackPt", "Minimal pT for both daughters", float) minTrackPt;
    PROPERTY(maxTrackEta_t, "maxTrackEta", "Maximal ETA for both daughters", float) maxTrackEta;

    PROPERTY(maxDoca_t, "maxDoca", "maxDoca description", float) maxDoca;
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "maxVertexChi2 description", float) maxVertexChi2;

    PROPERTY(minMass_t, "minMass", "Min mass of the composite", float) minMass;
    PROPERTY(maxMass_t, "maxMass", "Max mass of the composite", float) maxMass;

    PROPERTY(OppositeSign_t, "OppositeSign", "Selects opposite sign dimuon combinations", bool) OppositeSign;
    PROPERTY(minZ_t, "minZ", "minimum dimuon vertex z coordinate", float) minZ;
    PROPERTY(maxChi2Muon_t, "maxChi2Muon", "maximum muonID chi2corr value", float) maxChi2Muon;

    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;
    PROPERTY(enable_tupling_t, "enable_tupling", "Enable line tupling", bool) enable_tupling;

    DEVICE_OUTPUT(mass_t, float) mass;
    DEVICE_OUTPUT(transverse_momentum_t, float) transverse_momentum;

    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct di_muon_drell_yan_line_t : public SelectionAlgorithm,
                                    Parameters,
                                    CompositeParticleLine<di_muon_drell_yan_line_t, Parameters> {
    struct DeviceAccumulators {
      Allen::Monitoring::Histogram<>::DeviceType histogram_Z_mass;
      DeviceAccumulators(const di_muon_drell_yan_line_t& algo, const Allen::Context& ctx) :
        histogram_Z_mass(algo.m_histogram_Z_mass.data(ctx))
      {}
    };

    __device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const float> static get_input(
      const Parameters& parameters,
      const unsigned event_number,
      const unsigned i);

    __device__ static bool select(
      const Parameters&,
      const DeviceAccumulators&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const float>);

    __device__ static void monitor(
      const Parameters&,
      const DeviceAccumulators&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const float>,
      unsigned,
      bool);
    __device__ static void fill_tuples(
      const Parameters&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const float>,
      unsigned,
      bool);

    using monitoring_types = std::tuple<transverse_momentum_t, mass_t, evtNo_t, runNo_t>;

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};

    Property<minTrackP_t> m_minTrackP {this, 15.f * Gaudi::Units::GeV};
    Property<minTrackPt_t> m_minTrackPt {this, 1.2f * Gaudi::Units::GeV};
    Property<maxTrackEta_t> m_maxTrackEta {this, 4.9};

    Property<minMass_t> m_minMass {this, 5.f * Gaudi::Units::GeV};
    Property<maxMass_t> m_maxMass {this, 400.f * Gaudi::Units::GeV};

    Property<maxDoca_t> m_maxDoca {this, .15f * Gaudi::Units::mm};
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 20.f};

    Property<OppositeSign_t> m_only_select_opposite_sign {this, true};
    Property<minZ_t> m_minZ {this, -341.f * Gaudi::Units::mm};
    Property<maxChi2Muon_t> m_maxChi2Muon {this, 2.2};

    Property<enable_monitoring_t> m_enable_monitoring {this, false};
    Property<enable_tupling_t> m_enable_tupling {this, false};

    Allen::Monitoring::Histogram<> m_histogram_Z_mass {this, "Z_mass", "m(mu+mu-)", {100u, 60000.f, 120000.f}};
  };
} // namespace di_muon_drell_yan_line
