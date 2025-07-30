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
#include "EventLine.cuh"
#include "ParticleTypes.cuh"

namespace displaced_leptons_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    // TODO: For now, this is called a "track" container instead of a "particle"
    // container to trick the SelReport writer into not looking for individual
    // selected candidates. This line needs to be reworked to save individual
    // candidate information to the SelReport.
    DEVICE_INPUT(dev_track_container_t, Allen::Views::Physics::MultiEventBasicParticles) dev_track_container;
    DEVICE_INPUT(dev_track_isElectron_t, bool) dev_track_isElectron;
    DEVICE_INPUT(dev_brem_corrected_pt_t, float) dev_brem_corrected_pt;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;
  };

  struct displaced_leptons_line_t : public SelectionAlgorithm,
                                    Parameters,
                                    EventLine<displaced_leptons_line_t, Parameters> {

    struct DeviceProperties {
      float min_ipchi2;
      float min_pt;
      float min_BPVz;
      DeviceProperties(const displaced_leptons_line_t& algo, const Allen::Context&) :
        min_ipchi2(algo.m_min_ipchi2), min_pt(algo.m_min_pt), min_BPVz(algo.m_minBPVz)
      {}
    };

    __device__ static std::tuple<const Allen::Views::Physics::BasicParticles, const unsigned, const bool*, const float*>
    get_input(const Parameters&, const unsigned, const unsigned);

    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::BasicParticles, const unsigned, const bool*, const float*> input);

  private:
    Allen::Property<float> m_min_ipchi2 {this, "min_ipchi2", 7.4f, "Minimum ipchi2"};
    Allen::Property<float> m_min_pt {this, "min_pt", 1000.f, "Minimum pt"};
    Allen::Property<float> m_minBPVz {this,
                                      "min_BPVz",
                                      -330.f * Allen::Units::mm,
                                      "Minimum z for the associated best primary vertex"};
  };
} // namespace displaced_leptons_line
