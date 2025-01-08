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

#include "BeamlinePVConstants.cuh"
#include "Common.h"
#include "AlgorithmTypes.cuh"
#include "TrackBeamLineVertexFinder.cuh"
#include "VeloConsolidated.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "patPV_Definitions.cuh"
#include "FloatOperations.cuh"
#include <cstdint>

namespace pv_beamline_peak {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_zhisto_t, float) dev_zhisto;
    DEVICE_OUTPUT(dev_zpeaks_t, float) dev_zpeaks;
    DEVICE_OUTPUT(dev_number_of_zpeaks_t, unsigned) dev_number_of_zpeaks;
  };

  __global__ void pv_beamline_peak(
    Parameters,
    const int Nbins,
    const float zmin,
    const float dz,
    const float SMOG2_pp_separation,
    const float SMOG2_maxTrackZ0Err,
    const float pp_maxTrackZ0Err,
    const float SMOG2_minTracksInSeed,
    const float pp_minTracksInSeed,
    const float minDipDensity,
    const float minDensity);

  struct pv_beamline_peak_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

    Allen::Property<float> m_SMOG2_pp_separation {this,
                                                  "SMOG2_pp_separation",
                                                  BeamlinePVConstants::Common::SMOG2_pp_separation,
                                                  "z separation between the pp and SMOG2 luminous region"};
    Allen::Property<float> m_SMOG2_maxTrackZ0Err {this,
                                                  "SMOG2_maxTrackZ0Err",
                                                  BeamlinePVConstants::Common::SMOG2_maxTrackZ0Err,
                                                  "Maximum error for z0 extrapolation"};
    Allen::Property<float> m_pp_maxTrackZ0Err {this,
                                               "pp_maxTrackZ0Err",
                                               BeamlinePVConstants::Common::pp_maxTrackZ0Err,
                                               "Maximum error for z0 extrapolation"};
    Allen::Property<float> m_zmin {this, "zmin", BeamlinePVConstants::Common::zmin, "Minimum histogram z"};
    Allen::Property<float> m_dz {this, "dz", BeamlinePVConstants::Common::dz, "Histogram bin width"};
    Allen::Property<int> m_Nbins {this,
                                  "Nbins",
                                  BeamlinePVConstants::Common::Nbins,
                                  "Number of histogram bins (zmax - zmin)/dz"};
    Allen::Property<float> m_SMOG2_minTracksInSeed {this,
                                                    "SMOG2_minTracksInSeed",
                                                    BeamlinePVConstants::Peak::SMOG2_minTracksInSeed,
                                                    "Minimum number of tracks to accept a SMOG2 seed"};
    Allen::Property<float> m_pp_minTracksInSeed {this,
                                                 "pp_minTracksInSeed",
                                                 BeamlinePVConstants::Peak::pp_minTracksInSeed,
                                                 "Minimum number of tracks to accept a pp seed"};
    Allen::Property<float> m_minDensity {this, "minDensity", BeamlinePVConstants::Peak::minDensity, "minimum density"};
    Allen::Property<float> m_minDipDensity {this,
                                            "minDipDensity",
                                            BeamlinePVConstants::Peak::minDipDensity,
                                            "minimum dip density"};
  };
} // namespace pv_beamline_peak
