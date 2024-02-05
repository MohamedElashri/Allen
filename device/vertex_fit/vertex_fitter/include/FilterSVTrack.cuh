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

namespace FilterSVTrack {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_svs_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_svs;
    DEVICE_INPUT(dev_tracks_t, Allen::Views::Physics::MultiEventBasicParticles) dev_tracks;
    DEVICE_OUTPUT(dev_combination_number_t, unsigned) dev_combination_number;
    DEVICE_OUTPUT(dev_sv_idx_t, unsigned) dev_sv_idx;
    DEVICE_OUTPUT(dev_track_idx_t, unsigned) dev_track_idx;

    PROPERTY(SV_VCHI2_max_t, "SV_VCHI2_max", "max sv vertex chi2", float) SV_VCHI2_max;
    PROPERTY(SV_VZ_min_t, "SV_VZ_min", "min vertex z position of sv candidate", float) SV_VZ_min;
    PROPERTY(SV_VZ_max_t, "SV_VZ_max", "max vertex z position of sv candidate", float) SV_VZ_max;
    PROPERTY(SV_BPVVDCHI2_min_t, "SV_BPVVDCHI2_min", "min flight distance chi2 between sv and its best PV", float)
    SV_BPVVDCHI2_min;
    PROPERTY(SV_BPVVDZ_min_t, "SV_BPVVDZ_min", "min z vertex distance of sv w.r.t. its best PV", float) SV_BPVVDZ_min;
    PROPERTY(SV_BPVVDRHO_min_t, "SV_BPVVDRHO_min", "min radial vertex distance of sv w.r.t. its best PV", float)
    SV_BPVVDRHO_min;
    PROPERTY(SV_BPVDIRA_min_t, "SV_BPVDIRA_min", "min cosine of direction angle of sv w.r.t. its best PV", float)
    SV_BPVDIRA_min;
    PROPERTY(T_CHI2NDF_max_t, "T_CHI2NDF_max", "Maximum track chi2 per n.d.f. (VeloKalman)", float) T_CHI2NDF_max;
    PROPERTY(T_PT_min_t, "T_PT_min", "Minimal track pT", float) T_PT_min;
    PROPERTY(T_MIPCHI2_min_t, "T_MIPCHI2_min", "Minimal IP chi^2 of track w.r.t. any PV", float) T_MIPCHI2_min;
    PROPERTY(opening_angle_min_t, "opening_angle_min", "min angle between tracks from sv and companion track", float)
    opening_angle_min;
    PROPERTY(SV_T_DOCA_max_t, "SV_T_DOCA_max", "DOCA of sv and track", float) SV_T_DOCA_max;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void filter_sv_track(Parameters);

  struct filter_sv_track_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<SV_VCHI2_max_t> m_SV_VCHI2_max {this, 24.f};
    Property<SV_VZ_min_t> m_SV_VZ_min {this, -80.f * Gaudi::Units::mm};
    Property<SV_VZ_max_t> m_SV_VZ_max {this, 650.f * Gaudi::Units::mm};
    Property<SV_BPVVDCHI2_min_t> m_SV_BPVVDCHI2_min {this, 180.f};
    Property<SV_BPVVDZ_min_t> m_SV_BPVVDZ_min {this, 12.f * Gaudi::Units::mm};
    Property<SV_BPVVDRHO_min_t> m_SV_BPVVDRHO_min {this, 2.f * Gaudi::Units::mm};
    Property<SV_BPVDIRA_min_t> m_SV_BPVDIRA_min {this, 0.9997};
    Property<T_CHI2NDF_max_t> m_T_CHI2NDF_max {this, 10.f};
    Property<T_PT_min_t> m_T_PT_min {this, 150.f * Gaudi::Units::MeV};
    Property<T_MIPCHI2_min_t> m_T_MIPCHI2_min {this, 4.f};
    Property<opening_angle_min_t> m_opening_angle_min {this, 0.5f * Gaudi::Units::mrad};
    Property<SV_T_DOCA_max_t> m_SV_T_DOCA_max {this, 500.f * Gaudi::Units::um};
    Property<block_dim_t> m_block_dim {this, {{4, 64, 1}}};
  };
} // namespace FilterSVTrack
