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

#include "BackendCommon.h"
#include "AlgorithmTypes.cuh"
#include "BeamlinePVConstants.cuh"

namespace host_pv_validator {
  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_multi_final_vertices_t, PV::Vertex) dev_multi_final_vertices;
    DEVICE_INPUT(dev_number_of_multi_final_vertices_t, unsigned) dev_number_of_multi_final_vertices;
    HOST_INPUT(host_mc_events_t, const MCEvents*) host_mc_events;
  };

  struct host_pv_validator_t : public ValidationAlgorithm, Parameters {
    inline void set_arguments_size(ArgumentReferences<Parameters>, const RuntimeOptions&, const Constants&) const {}

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;

  private:
    Allen::Property<std::string> m_root_output_filename {this,
                                                         "root_output_filename",
                                                         "PrCheckerPlots.root",
                                                         "root output filename"};
    Allen::Property<float> m_pp_minNumTracksPerVertex {this,
                                                       "pp_minNumTracksPerVertex",
                                                       BeamlinePVConstants::MultiFitter::pp_minNumTracksPerVertex,
                                                       "Min number of tracks to accpet a pp vertex"};
  };
} // namespace host_pv_validator
