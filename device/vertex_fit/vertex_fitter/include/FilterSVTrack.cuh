/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "VertexDefinitions.cuh"
#include "VertexFitDeviceFunctions.cuh"
#include "AssociateConsolidated.cuh"
#include "MassDefinitions.h"
#include "States.cuh"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include <limits>

namespace FilterSVTrack {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_svs_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_svs;
    DEVICE_INPUT(dev_tracks_t, Allen::Views::Physics::MultiEventBasicParticles) dev_tracks;
    DEVICE_OUTPUT(dev_combination_offsets_t, unsigned) dev_combination_offsets;
    HOST_OUTPUT(host_number_of_combinations_t, unsigned) host_number_of_combinations;
    DEVICE_OUTPUT(dev_sv_idx_t, unsigned) dev_sv_idx;
    DEVICE_OUTPUT(dev_track_idx_t, unsigned) dev_track_idx;
  };

  __global__ void filter_sv_track(
    Parameters,
    const float SV_VZ_min,
    const float SV_VZ_max,
    const float SV_BPVIP_min,
    const float SV_BPVVDZ_min,
    const float SV_BPVVDRHO_min,
    const float SV_BPVDIRA_min,
    const float T_CHI2NDF_max,
    const float T_PT_min,
    const float T_MIPCHI2_min,
    const float T_MIPCHI2_max,
    const float T_MIP_min,
    const float T_MIP_max,
    const float SV_T_DOCA_max,
    const float opening_angle_min,
    const bool require_same_pv,
    const bool require_os_pair);

  struct filter_sv_track_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<float> m_SV_VZ_min {this,
                                        "SV_VZ_min",
                                        -180.f * Allen::Units::mm,
                                        "min vertex z position of sv candidate"};
    Allen::Property<float> m_SV_VZ_max {this,
                                        "SV_VZ_max",
                                        650.f * Allen::Units::mm,
                                        "max vertex z position of sv candidate"};
    Allen::Property<float> m_SV_BPVIP_min {this,
                                           "SV_BPVIP_min",
                                           32.f * Allen::Units::um,
                                           "min IP of sv w.r.t. its best PV"};
    Allen::Property<float> m_SV_BPVVDZ_min {this,
                                            "SV_BPVVDZ_min",
                                            24.f * Allen::Units::mm,
                                            "min z vertex distance of sv w.r.t. its best PV"};
    Allen::Property<float> m_SV_BPVVDRHO_min {this,
                                              "SV_BPVVDRHO_min",
                                              3.f * Allen::Units::mm,
                                              "min radial vertex distance of sv w.r.t. its best PV"};
    Allen::Property<float> m_SV_BPVDIRA_min {this,
                                             "SV_BPVDIRA_min",
                                             0.9999f,
                                             "min cosine of direction angle of sv w.r.t. its best PV"};
    Allen::Property<float> m_T_CHI2NDF_max {this, "T_CHI2NDF_max", 10.f, "Maximum track chi2 per n.d.f. (VeloKalman)"};
    Allen::Property<float> m_T_PT_min {this, "T_PT_min", 100.f * Allen::Units::MeV, "Minimal track pT"};
    Allen::Property<float> m_T_MIPCHI2_min {this, "T_MIPCHI2_min", 6.f, "Minimal IP chi^2 of track w.r.t. any PV"};
    Allen::Property<float> m_T_MIPCHI2_max {this,
                                            "T_MIPCHI2_max",
                                            std::numeric_limits<float>::max(),
                                            "Maximum minimal IP chi^2 of track w.r.t. any PV"};
    Allen::Property<float> m_T_MIP_min {this, "T_MIP_min", 0.f, "Minimal IP of track w.r.t. any PV"};
    Allen::Property<float> m_T_MIP_max {this,
                                        "T_MIP_max",
                                        std::numeric_limits<float>::max(),
                                        "Maximum minimal IP of track w.r.t. any PV"};
    Allen::Property<float> m_SV_T_DOCA_max {this, "SV_T_DOCA_max", 150.f * Allen::Units::um, "DOCA of sv and track"};
    Allen::Property<float> m_opening_angle_min {this,
                                                "opening_angle_min",
                                                0.5f * Allen::Units::mrad,
                                                "min angle between tracks from sv and companion track"};
    Allen::Property<bool> m_require_same_pv {this,
                                             "require_same_pv",
                                             false,
                                             "Require track and SV to have the same associated PV."};
    Allen::Property<bool> m_require_os_pair {this,
                                             "require_os_pair",
                                             true,
                                             "Requires that the SV consists of two tracks with opposite charge."};
    Allen::Property<dim3> m_block_dim {this, "block_dim", {128, 4, 1}, "block dimensions"};
  };
} // namespace FilterSVTrack
