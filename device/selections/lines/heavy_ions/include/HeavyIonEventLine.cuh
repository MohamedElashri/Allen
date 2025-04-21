/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "EventLine.cuh"
#include "VeloConsolidated.cuh"
#include "CaloDigit.cuh"
#include "CaloGeometry.cuh"
#include "PV_Definitions.cuh"

namespace heavy_ion_event_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_velo_tracks_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks;
    DEVICE_INPUT(dev_velo_states_t, Allen::Views::Physics::KalmanStates) dev_velo_states;
    DEVICE_INPUT(dev_long_track_particle_container_t, Allen::Views::Physics::MultiEventBasicParticles)
    dev_long_track_particle_container;
    DEVICE_INPUT(dev_total_ecal_e_t, float) dev_total_ecal_e;
    DEVICE_INPUT(dev_pvs_t, PV::Vertex) dev_pvs;
    DEVICE_INPUT(dev_number_of_pvs_t, unsigned) dev_number_of_pvs;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;
  };

  struct heavy_ion_event_line_t : public SelectionAlgorithm, Parameters, EventLine<heavy_ion_event_line_t, Parameters> {
    struct DeviceProperties {
      int min_velo_tracks_PbPb;
      int max_velo_tracks_PbPb;
      int min_long_tracks;
      int max_long_tracks;
      int min_velo_tracks_SMOG;
      int max_velo_tracks_SMOG;
      int min_pvs_PbPb;
      int max_pvs_PbPb;
      int min_pvs_SMOG;
      int max_pvs_SMOG;
      float min_ecal_e;
      float max_ecal_e;
      float PbPb_SMOG_z_separation;
      DeviceProperties(const heavy_ion_event_line_t& algo, const Allen::Context&) :
        min_velo_tracks_PbPb(algo.m_min_velo_tracks_PbPb), max_velo_tracks_PbPb(algo.m_max_velo_tracks_PbPb),
        min_long_tracks(algo.m_min_long_tracks), max_long_tracks(algo.m_max_long_tracks),
        min_velo_tracks_SMOG(algo.m_min_velo_tracks_SMOG), max_velo_tracks_SMOG(algo.m_max_velo_tracks_SMOG),
        min_pvs_PbPb(algo.m_min_pvs_PbPb), max_pvs_PbPb(algo.m_max_pvs_PbPb), min_pvs_SMOG(algo.m_min_pvs_SMOG),
        max_pvs_SMOG(algo.m_max_pvs_SMOG), min_ecal_e(algo.m_min_ecal_e), max_ecal_e(algo.m_max_ecal_e),
        PbPb_SMOG_z_separation(algo.m_PbPb_SMOG_z_separation)
      {}
    };

    __device__ static std::tuple<unsigned> get_input(const Parameters&, const unsigned, const unsigned);

    __device__ static bool select(const Parameters&, const DeviceProperties&, std::tuple<unsigned> input);

  private:
    Allen::Property<int> m_min_velo_tracks_PbPb {this,
                                                 "min_velo_tracks_PbPb",
                                                 0,
                                                 "Minimum number of VELO tracks in the PbPb region"};
    Allen::Property<int> m_max_velo_tracks_PbPb {this,
                                                 "max_velo_tracks_PbPb",
                                                 -1,
                                                 "Maximum number of VELO tracks in the PbPb region"};
    Allen::Property<int> m_min_long_tracks {this, "min_long_tracks", 0, "Minimum number of Long tracks"};
    Allen::Property<int> m_max_long_tracks {this, "max_long_tracks", -1, "Maximum number of Long tracks"};
    Allen::Property<int> m_min_velo_tracks_SMOG {this,
                                                 "min_velo_tracks_SMOG",
                                                 0,
                                                 "Minimum number of VELO tracks in the SMOG region"};
    Allen::Property<int> m_max_velo_tracks_SMOG {this,
                                                 "max_velo_tracks_SMOG",
                                                 -1,
                                                 "Maximum number of VELO tracks in the SMOG region"};
    Allen::Property<int> m_min_pvs_PbPb {this, "min_pvs_PbPb", 0, "Minimum number of PVs in the PbPb region"};
    Allen::Property<int> m_max_pvs_PbPb {this, "max_pvs_PbPb", -1, "Maximum number of PVs in the PbPb region"};
    Allen::Property<int> m_min_pvs_SMOG {this, "min_pvs_SMOG", 0, "Minimum number of PVs in the SMOG region"};
    Allen::Property<int> m_max_pvs_SMOG {this, "max_pvs_SMOG", -1, "Maximum number of PVs in the SMOG region"};
    Allen::Property<float> m_min_ecal_e {this, "min_ecal_e", 0.f, "Minimum ECAL energy"};
    Allen::Property<float> m_max_ecal_e {this, "max_ecal_e", -1.f, "Maximum ECAL energy"};
    Allen::Property<float> m_PbPb_SMOG_z_separation {this, "PbPb_SMOG_z_separation", -330.f, "PbPb_SMOG_z_separation"};
  };
} // namespace heavy_ion_event_line
