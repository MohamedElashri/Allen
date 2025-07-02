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

#include "AlgorithmTypes.cuh"
#include "CompositeParticleLine.cuh"

namespace displaced_dielectron_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    // Kalman fitted tracks
    DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
    // ECAL
    DEVICE_INPUT(dev_track_isElectron_t, bool) dev_track_isElectron;
    DEVICE_INPUT(dev_electronidnn_t, float) dev_electronidnn;
    DEVICE_INPUT(dev_brem_corrected_pt_t, float) dev_brem_corrected_pt;
    // Outputs
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
    DEVICE_OUTPUT(pt_t, float) pt;
    DEVICE_OUTPUT(electron_nn_t, float) electron_nn;
    DEVICE_OUTPUT(ipchi2_t, float) ipchi2;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct displaced_dielectron_line_t : public SelectionAlgorithm,
                                       Parameters,
                                       CompositeParticleLine<displaced_dielectron_line_t, Parameters> {

    struct DeviceProperties {
      float minIPChi2;
      float maxDOCA;
      float minPT;
      float maxVtxChi2;
      float minZ;
      bool oppositeSign;
      float minElectronNN;
      bool useNN;
      DeviceProperties(const displaced_dielectron_line_t& algo, const Allen::Context&) :
        minIPChi2(algo.m_MinIPChi2), maxDOCA(algo.m_MaxDOCA), minPT(algo.m_MinPT), maxVtxChi2(algo.m_MaxVtxChi2),
        minZ(algo.m_MinZ), oppositeSign(algo.m_opposite_sign), minElectronNN(algo.m_minElectronNN), useNN(algo.m_useNN)
      {}
    };
    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned>);

    __device__ static std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);

    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
      unsigned index,
      bool sel);

    using monitoring_types = std::tuple<pt_t, electron_nn_t, ipchi2_t, evtNo_t, runNo_t>;

  private:
    // Displaced dielectron selections.
    Allen::Property<float> m_MinIPChi2 {this, "MinIPChi2", 7.4f, "Min IP Chi2"};
    Allen::Property<float> m_MaxDOCA {this, "MaxDOCA", 0.082f, "Max DOCA"};
    Allen::Property<float> m_MinPT {this, "MinPT", 500.f, "Min PT"};
    Allen::Property<float> m_MaxVtxChi2 {this, "MaxVtxChi2", 7.4f, "Max vertex chi2"};
    Allen::Property<float> m_MinZ {this, "MinZ", -330.f * Allen::Units::mm, "Min z dielectron coordinate"};
    Allen::Property<bool> m_opposite_sign {this, "OppositeSign", true, "Selects opposite sign dielectron combinations"};
    Allen::Property<float> m_minElectronNN {this, "minElectronNN", 0.1, "min NN evaluation"};
    Allen::Property<bool> m_useNN {this, "useNN", true, "useNN"};
  };
} // namespace displaced_dielectron_line
