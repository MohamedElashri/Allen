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
// For the Offline Data Quality Validator, not all information
// needed about long tracks are easily available to the host.
// For this reason the long track module is made as a device
// algorithm instead.

namespace data_quality_validator_long {
  struct long_track_info {
    float ip_x, ip_y, ip_chi2, chi2;
    int is_muon, is_electron;

    float cov[4][4] = {{0}};
    float tx, ty, qop, eta, pt;
  };

  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_long_tracks_t, unsigned) host_number_of_reconstructed_long_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventBasicParticles) dev_particle_container;
    DEVICE_INPUT(dev_offsets_long_tracks_t, unsigned) dev_offsets_long_tracks;

    DEVICE_OUTPUT(dev_dq_long_track_info_t, data_quality_validator_long::long_track_info) dev_dq_long_track_info;
  };

  __global__ void copyLongTrackIP(Parameters);

  struct data_quality_validator_long_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

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
    // Block size should be < the average number of long tracks
    // to avoid GPU threads idling, 32 has been chosen as this number
    // it shouldn't be set to less than 32 as this is the warp size
    Allen::Property<dim3> m_block_dim {this, "block_dim", {32, 1, 1}, "block dimensions"};
    Allen::Property<bool> m_enable_tupling {this, "enable_tupling", true, "Enable Tupling"};
  };
} // namespace data_quality_validator_long
