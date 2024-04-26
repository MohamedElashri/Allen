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
#include "pv_beamline_cleanup.cuh"

INSTANTIATE_ALGORITHM(pv_beamline_cleanup::pv_beamline_cleanup_t)

void pv_beamline_cleanup::pv_beamline_cleanup_t::init()
{
  m_histogram_smogpv_z.x_axis().nBins = property<nbins_histo_smogpvz_t>();
  m_histogram_smogpv_z.x_axis().minValue = property<min_histo_smogpvz_t>();
  m_histogram_smogpv_z.x_axis().maxValue = property<max_histo_smogpvz_t>();
}

void pv_beamline_cleanup::pv_beamline_cleanup_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_multi_final_vertices_t>(arguments, first<host_number_of_events_t>(arguments) * PV::max_number_vertices);
  set_size<dev_number_of_multi_final_vertices_t>(arguments, first<host_number_of_events_t>(arguments));
}

void pv_beamline_cleanup::pv_beamline_cleanup_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_number_of_multi_final_vertices_t>(arguments, 0, context);

  global_function(pv_beamline_cleanup)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments,
    m_pvs.data(context),
    m_histogram_n_pvs.data(context),
    m_histogram_n_smogpvs.data(context),
    m_histogram_pv_x.data(context),
    m_histogram_pv_y.data(context),
    m_histogram_pv_z.data(context),
    m_histogram_smogpv_z.data(context));
}

__global__ void pv_beamline_cleanup::pv_beamline_cleanup(
  pv_beamline_cleanup::Parameters parameters,
  Allen::Monitoring::AveragingCounter<>::DeviceType dev_n_pvs_counter,
  Allen::Monitoring::Histogram<>::DeviceType dev_n_pvs_histo,
  Allen::Monitoring::Histogram<>::DeviceType dev_n_smogpvs_histo,
  Allen::Monitoring::Histogram<>::DeviceType dev_pv_x_histo,
  Allen::Monitoring::Histogram<>::DeviceType dev_pv_y_histo,
  Allen::Monitoring::Histogram<>::DeviceType dev_pv_z_histo,
  Allen::Monitoring::Histogram<>::DeviceType dev_smogpv_z_histo)
{

  __shared__ unsigned tmp_number_vertices[1];
  __shared__ unsigned tmp_number_SMOG_vertices[1];
  *tmp_number_vertices = 0;
  *tmp_number_SMOG_vertices = 0;

  __syncthreads();

  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const PV::Vertex* vertices = parameters.dev_multi_fit_vertices + event_number * PV::max_number_vertices;
  PV::Vertex* final_vertices = parameters.dev_multi_final_vertices + event_number * PV::max_number_vertices;
  const unsigned number_of_multi_fit_vertices = parameters.dev_number_of_multi_fit_vertices[event_number];
  // loop over all rec PVs, check if another one is within certain sigma range, only fill if not
  for (unsigned i_pv = threadIdx.x; i_pv < number_of_multi_fit_vertices; i_pv += blockDim.x) {
    bool unique = true;
    PV::Vertex vertex1 = vertices[i_pv];
    for (unsigned j_pv = 0; j_pv < number_of_multi_fit_vertices; j_pv++) {
      if (i_pv == j_pv) continue;
      PV::Vertex vertex2 = vertices[j_pv];
      float z1 = vertex1.position.z;
      float z2 = vertex2.position.z;
      float variance1 = vertex1.cov22;
      float variance2 = vertex2.cov22;
      float chi2_dist = (z1 - z2) * (z1 - z2);
      chi2_dist = chi2_dist / (variance1 + variance2);
      if (chi2_dist < parameters.minChi2Dist && vertex1.nTracks < vertex2.nTracks) {
        unique = false;
      }
    }
    if (unique) {
      auto vtx_index = atomicAdd(tmp_number_vertices, 1);
      final_vertices[vtx_index] = vertex1;

      // monitoring
      if (-200 < vertex1.position.z && vertex1.position.z < 200) {
        dev_pv_x_histo.increment(vertex1.position.x);
        dev_pv_y_histo.increment(vertex1.position.y);
        dev_pv_z_histo.increment(vertex1.position.z);
      }

      if (dev_smogpv_z_histo.inAcceptance(vertex1.position.z)) {
        dev_smogpv_z_histo.increment(vertex1.position.z);
        atomicAdd(tmp_number_SMOG_vertices, 1);
      }
    }
  }
  __syncthreads();
  parameters.dev_number_of_multi_final_vertices[event_number] = *tmp_number_vertices;

  if (threadIdx.x == 0) {
    dev_n_pvs_histo.increment(*tmp_number_vertices);
    dev_n_smogpvs_histo.increment(*tmp_number_SMOG_vertices);
    dev_n_pvs_counter.add(*tmp_number_vertices);
  }
}
