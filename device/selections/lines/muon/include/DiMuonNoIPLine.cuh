/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "ParKalmanFilter.cuh"
#include "AlgorithmTypes.cuh"
#include "CompositeParticleLine.cuh"
#include "ROOTService.h"
#include "MassDefinitions.h"
#include <array>

#include "AllenMonitoring.h"

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
    DEVICE_OUTPUT(dev_muon_nn_t, float) dev_muon_nn;
    DEVICE_OUTPUT(dev_eventNum_t, int16_t) dev_eventNum;
    DEVICE_OUTPUT(pt_t, float) pt;
    DEVICE_OUTPUT(ipchi2_t, float) ipchi2;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
    DEVICE_INPUT(dev_muonid_nn_t, float) dev_muonid_nn;
    DEVICE_INPUT(dev_chi2muon_t, float) dev_chi2muon;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
  };

  struct di_muon_no_ip_line_t : public SelectionAlgorithm,
                                Parameters,
                                CompositeParticleLine<di_muon_no_ip_line_t, Parameters> {
    struct DeviceProperties {
      float minTrackPtPROD;
      float minTrackP;
      float maxDoca;
      float maxVertexChi2;
      float maxTrChi2;
      bool ss_on;
      float minPt;
      float minZ;
      float maxChi2Muon;
      float minNN;
      Allen::Monitoring::LogHistogram<>::DeviceType histogram_prompt_q;
      DeviceProperties(const di_muon_no_ip_line_t& algo, const Allen::Context& ctx) :
        minTrackPtPROD(algo.m_minTrackPtPROD), minTrackP(algo.m_minTrackP), maxDoca(algo.m_maxDoca),
        maxVertexChi2(algo.m_maxVertexChi2), maxTrChi2(algo.m_maxTrChi2), ss_on(algo.m_ss_on.value()),
        minPt(algo.m_minPt), minZ(algo.m_minZ), maxChi2Muon(algo.m_maxChi2Muon), minNN(algo.m_minNN),
        histogram_prompt_q(algo.m_histogram_prompt_q.data(ctx))
      {}
    };
    __device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const float> static get_input(
      const Parameters&,
      const unsigned,
      const unsigned);
    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const float>);
    __device__ static void monitor(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const float>,
      unsigned,
      bool);
    __device__ static bool fill_tuples(
      const Parameters& parameters,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input,
      unsigned index,
      bool sel);

    using monitoring_types = std::tuple<dev_muon_nn_t, pt_t, ipchi2_t, evtNo_t, runNo_t>;

  private:
    Allen::Monitoring::LogHistogram<> m_histogram_prompt_q {this,
                                                            "dimuon_q",
                                                            "dimuon q",
                                                            {10390, 0.f, 70e3, 2.71998658e-03f, 2.34546735e+03f, 1.f}};

  private:
    Allen::Property<float> m_minTrackPtPROD {this,
                                             "minTrackPtPROD",
                                             1.f * Allen::Units::GeV* Allen::Units::GeV,
                                             "minTrackPtPROD description"}; // run 2 value: 1.*GeV*GeV
    Allen::Property<float> m_minTrackP {this,
                                        "minTrackP",
                                        5000.f * Allen::Units::MeV,
                                        "minTrackP description"};                   // run 2 value: 10000
    Allen::Property<float> m_maxDoca {this, "maxDoca", .3f, "maxDoca description"}; // run 2 value: 0.1
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 9.f, "maxVertexChi2 description"}; // run 2 value: 9
    Allen::Property<float> m_maxTrChi2 {this, "maxTrChi2", 3.f, "maxTrChi2 description"};             // run 2 value: 3
    Allen::Property<bool> m_ss_on {this, "ss_on", false, "ss_on description"};
    Allen::Property<float> m_minPt {this, "minPt", 1.f * Allen::Units::GeV, "minPt description"};
    Allen::Property<float> m_minZ {this, "minZ", -330.f * Allen::Units::mm, "minimum vertex z coordinate"};
    Allen::Property<float> m_maxChi2Muon {this, "maxChi2Muon", 1.3f, "maximum Chi2Muon evaluation"};
    Allen::Property<float> m_minNN {this, "minNN", 0.74f, "minimum NN evaluation"};
  };
} // namespace di_muon_no_ip_line
