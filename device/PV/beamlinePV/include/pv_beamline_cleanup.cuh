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
#include "FloatOperations.cuh"
#include <cstdint>

#ifndef ALLEN_STANDALONE
#include <Gaudi/Accumulators.h>
#include "GaudiMonitoring.h"
#endif

namespace pv_beamline_cleanup {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_multi_fit_vertices_t, PV::Vertex) dev_multi_fit_vertices;
    DEVICE_INPUT(dev_number_of_multi_fit_vertices_t, unsigned) dev_number_of_multi_fit_vertices;
    DEVICE_OUTPUT(dev_multi_final_vertices_t, PV::Vertex) dev_multi_final_vertices;
    DEVICE_OUTPUT(dev_number_of_multi_final_vertices_t, unsigned) dev_number_of_multi_final_vertices;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
    PROPERTY(minChi2Dist_t, "minChi2Dist", "minimum chi2 distance", float) minChi2Dist;

    PROPERTY(nbins_histo_smogpvz_t, "nbins_histo_smogpvz", "Number of bins for SMOGPVz histogram", unsigned)
    nbins_histo_smogpvz;
    PROPERTY(min_histo_smogpvz_t, "min_histo_smogpvz", "Minimum of SMOGPVz histogram", float) min_histo_smogpvz;
    PROPERTY(max_histo_smogpvz_t, "max_histo_smogpvz", "Maximum of SMOGPVz histogram", float) max_histo_smogpvz;
  };

  __global__ void pv_beamline_cleanup(
    Parameters,
    gsl::span<unsigned>,
    gsl::span<unsigned>,
    gsl::span<unsigned>,
    gsl::span<unsigned>,
    gsl::span<unsigned>,
    gsl::span<unsigned>,
    gsl::span<unsigned>);

  struct pv_beamline_cleanup_t : public DeviceAlgorithm, Parameters {
    void init();
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{32, 1, 1}}};
    Property<minChi2Dist_t> m_minChi2Dist {this, BeamlinePVConstants::CleanUp::minChi2Dist};
    Property<nbins_histo_smogpvz_t> m_nbins_histo_smogpvz {this, 100};
    Property<min_histo_smogpvz_t> m_min_histo_smogpvz {this, -600.f};
    Property<max_histo_smogpvz_t> m_max_histo_smogpvz {this, -200.f};

#ifndef ALLEN_STANDALONE
    Gaudi::Accumulators::AveragingCounter<>* m_pvs;
    gaudi_monitoring::Lockable_Histogram<>* histogram_n_pvs;
    gaudi_monitoring::Lockable_Histogram<>* histogram_n_smogpvs;
    gaudi_monitoring::Lockable_Histogram<>* histogram_pv_x;
    gaudi_monitoring::Lockable_Histogram<>* histogram_pv_y;
    gaudi_monitoring::Lockable_Histogram<>* histogram_pv_z;
    gaudi_monitoring::Lockable_Histogram<>* histogram_smogpv_z;
#endif
  };
} // namespace pv_beamline_cleanup
