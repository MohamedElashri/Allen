/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
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

    PROPERTY(zmin_t, "zmin", "Minimum histogram z", float) zmin;
    PROPERTY(dz_t, "dz", "Histogram bin width", float) dz;
    PROPERTY(Nbins_t, "Nbins", "Number of histogram bins (zmax - zmin)/dz", int) Nbins;
    PROPERTY(
      SMOG2_pp_separation_t,
      "SMOG2_pp_separation",
      "z separation between the pp and SMOG2 luminous region",
      float)
    SMOG2_pp_separation;
    PROPERTY(SMOG2_maxTrackZ0Err_t, "SMOG2_maxTrackZ0Err", "Maximum error for z0 extrapolation", float)
    SMOG2_maxTrackZ0Err;
    PROPERTY(pp_maxTrackZ0Err_t, "pp_maxTrackZ0Err", "Maximum error for z0 extrapolation", float) pp_maxTrackZ0Err;
    PROPERTY(minDensity_t, "minDensity", "minimum density", float) minDensity;
    PROPERTY(minDipDensity_t, "minDipDensity", "minimum dip density", float) minDipDensity;
    PROPERTY(SMOG2_minTracksInSeed_t, "SMOG2_minTracksInSeed", "Minimum number of tracks to accept a SMOG2 seed", float)
    SMOG2_minTracksInSeed;
    PROPERTY(pp_minTracksInSeed_t, "pp_minTracksInSeed", "Minimum number of tracks to accept a pp seed", float)
    pp_minTracksInSeed;
  };

  __global__ void pv_beamline_peak(Parameters);

  struct pv_beamline_peak_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

    Property<SMOG2_pp_separation_t> m_SMOG2_pp_separation {this, BeamlinePVConstants::Common::SMOG2_pp_separation};
    Property<SMOG2_maxTrackZ0Err_t> m_SMOG2_maxTrackZ0Err {this, BeamlinePVConstants::Common::SMOG2_maxTrackZ0Err};
    Property<pp_maxTrackZ0Err_t> m_pp_maxTrackZ0Err {this, BeamlinePVConstants::Common::pp_maxTrackZ0Err};
    Property<zmin_t> m_zmin {this, BeamlinePVConstants::Common::zmin};
    Property<dz_t> m_dz {this, BeamlinePVConstants::Common::dz};
    Property<Nbins_t> m_Nbins {this, BeamlinePVConstants::Common::Nbins};
    Property<SMOG2_minTracksInSeed_t> m_SMOG2_minTracksInSeed {this, BeamlinePVConstants::Peak::SMOG2_minTracksInSeed};
    Property<pp_minTracksInSeed_t> m_pp_minTracksInSeed {this, BeamlinePVConstants::Peak::pp_minTracksInSeed};
    Property<minDensity_t> m_minDensity {this, BeamlinePVConstants::Peak::minDensity};
    Property<minDipDensity_t> m_minDipDensity {this, BeamlinePVConstants::Peak::minDipDensity};
  };
} // namespace pv_beamline_peak
