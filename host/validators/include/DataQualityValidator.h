/*****************************************************************************\
* (c) Copyright 2023-2024 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "SciFiEventModel.cuh"
#include "States.cuh"
#include "AlgorithmTypes.cuh"
#include "LookingForwardConstants.cuh"
#include "ParKalmanFittedTrack.cuh"
#include "ParKalmanMath.cuh"
#include "PV_Definitions.cuh"
#include "patPV_Definitions.cuh"
#include "ParticleTypes.cuh"
#include "CheckerTracks.cuh"
#include "CheckerInvoker.h"
#include "KalmanChecker.h"

#include "VeloConsolidated.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"

#include "ROOTService.h"

namespace data_quality_validator_velo {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_offsets_velo_tracks_t, unsigned) dev_offsets_velo_tracks;
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned) dev_offsets_all_velo_tracks;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned) dev_offsets_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_track_hits_t, char) dev_velo_track_hits;
    DEVICE_INPUT(dev_velo_kalman_states_t, char) dev_velo_kalman_states;
  };

  struct data_quality_validator_velo_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      [[maybe_unused]] ArgumentReferences<Parameters> arguments,
      [[maybe_unused]] const RuntimeOptions&,
      [[maybe_unused]] const Constants&) const {};

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

    void output_monitor(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Allen::Context& context) const;

  private:
    Allen::Property<bool> m_enable_tupling {this, "enable_tupling", true, "Enable Tupling"};
  };
} // namespace data_quality_validator_velo

namespace data_quality_validator_pv {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_multi_fit_vertices_t, PV::Vertex) dev_multi_fit_vertices;
    DEVICE_INPUT(dev_number_of_multi_fit_vertices_t, unsigned) dev_number_of_multi_fit_vertices;
  };

  struct data_quality_validator_pv_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      [[maybe_unused]] ArgumentReferences<Parameters> arguments,
      [[maybe_unused]] const RuntimeOptions&,
      [[maybe_unused]] const Constants&) const {};

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

    void output_monitor(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Allen::Context& context) const;

  private:
    Allen::Property<bool> m_enable_tupling {this, "enable_tupling", true, "Enable Tupling"};
  };
} // namespace data_quality_validator_pv

namespace data_quality_validator_occupancy {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_station_ocurrences_offset_t, unsigned) dev_station_ocurrences_offset;
    DEVICE_INPUT(dev_velo_offsets_estimated_input_size_t, unsigned) dev_velo_offsets_estimated_input_size;
    DEVICE_INPUT(dev_offsets_velo_tracks_t, unsigned) dev_offsets_velo_tracks;
    DEVICE_INPUT(dev_scifi_hit_offsets_t, unsigned) dev_scifi_hit_offsets;
    DEVICE_INPUT(dev_ecal_clusters_offsets_t, unsigned) dev_ecal_clusters_offsets;
    DEVICE_INPUT(dev_scifi_seedsXZ_t, unsigned) dev_scifi_seedsXZ;
  };

  struct data_quality_validator_occupancy_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      [[maybe_unused]] ArgumentReferences<Parameters> arguments,
      [[maybe_unused]] const RuntimeOptions&,
      [[maybe_unused]] const Constants&) const {};

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

    void output_monitor(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Allen::Context& context) const;

  private:
    Allen::Property<bool> m_enable_tupling {this, "enable_tupling", true, "Enable Tupling"};
  };
} // namespace data_quality_validator_occupancy
