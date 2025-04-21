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

namespace di_muon_track_eff_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
  };

  struct di_muon_track_eff_line_t : public SelectionAlgorithm,
                                    Parameters,
                                    CompositeParticleLine<di_muon_track_eff_line_t, Parameters> {

    struct DeviceProperties {
      float DMTrackEffM0;
      float DMTrackEffM1;
      float DMTrackEffMinZ;
      bool oppositeSign;
      DeviceProperties(const di_muon_track_eff_line_t& algo, const Allen::Context&) :
        DMTrackEffM0(algo.m_DMTrackEffM0), DMTrackEffM1(algo.m_DMTrackEffM1), DMTrackEffMinZ(algo.m_DMTrackEffMinZ),
        oppositeSign(algo.m_opposite_sign.value())
      {}
    };
    __device__ static bool
    select(const Parameters&, const DeviceProperties&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

  private:
    // Mass window around J/psi meson.
    Allen::Property<float> m_DMTrackEffM0 {this, "DMTrackEffM0", 2900.f, "DMTrackEffM0 description"};
    Allen::Property<float> m_DMTrackEffM1 {this, "DMTrackEffM1", 3100.f, "DMTrackEffM1 description"};
    Allen::Property<float> m_DMTrackEffMinZ {this, "DMTrackEffMinZ", -330.f, "MinZ for DMTrackEff"};
    Allen::Property<bool> m_opposite_sign {this, "OppositeSign", true, "Selects opposite sign dimuon combinations"};
  };
} // namespace di_muon_track_eff_line
