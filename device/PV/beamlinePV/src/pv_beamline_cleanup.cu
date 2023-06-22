/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "pv_beamline_cleanup.cuh"

INSTANTIATE_ALGORITHM(pv_beamline_cleanup::pv_beamline_cleanup_t)

void pv_beamline_cleanup::pv_beamline_cleanup_t::init()
{
#ifndef ALLEN_STANDALONE
  m_pvs = new Gaudi::Accumulators::AveragingCounter<> {this, "n_PVs"};
  histogram_n_pvs = new gaudi_monitoring::Lockable_Histogram<> {{this, "n_pvs_event", "n_pvs_event", {20, 0, 20}}, {}};
  histogram_pv_x = new gaudi_monitoring::Lockable_Histogram<> {{this, "pv_x", "pv_x", {100, -2.f, 2.f}}, {}};
  histogram_pv_y = new gaudi_monitoring::Lockable_Histogram<> {{this, "pv_y", "pv_y", {100, -2.f, 2.f}}, {}};
  histogram_pv_z = new gaudi_monitoring::Lockable_Histogram<> {{this, "pv_z", "pv_z", {100, -200.f, 200.f}}, {}};
#endif
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
  auto dev_n_pvs_counter = make_device_buffer<unsigned>(arguments, 1u);
  auto dev_n_pvs_histo = make_device_buffer<unsigned>(arguments, 20u);
  auto dev_pv_x_histo = make_device_buffer<unsigned>(arguments, 100u);
  auto dev_pv_y_histo = make_device_buffer<unsigned>(arguments, 100u);
  auto dev_pv_z_histo = make_device_buffer<unsigned>(arguments, 100u);
  Allen::memset_async(dev_n_pvs_counter.data(), 0, dev_n_pvs_counter.size() * sizeof(unsigned), context);
  Allen::memset_async(dev_n_pvs_histo.data(), 0, dev_n_pvs_histo.size() * sizeof(unsigned), context);
  Allen::memset_async(dev_pv_x_histo.data(), 0, dev_pv_x_histo.size() * sizeof(unsigned), context);
  Allen::memset_async(dev_pv_y_histo.data(), 0, dev_pv_y_histo.size() * sizeof(unsigned), context);
  Allen::memset_async(dev_pv_z_histo.data(), 0, dev_pv_z_histo.size() * sizeof(unsigned), context);

  Allen::memset_async<dev_number_of_multi_final_vertices_t>(arguments, 0, context);

  global_function(pv_beamline_cleanup)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments,
    dev_n_pvs_counter.get(),
    dev_n_pvs_histo.get(),
    dev_pv_x_histo.get(),
    dev_pv_y_histo.get(),
    dev_pv_z_histo.get());

#ifndef ALLEN_STANDALONE
  gaudi_monitoring::fill(
    arguments,
    context,
    std::tuple {std::tuple {dev_n_pvs_histo.get(), histogram_n_pvs, 0, 20},
                std::tuple {dev_pv_x_histo.get(), histogram_pv_x, -2, 2},
                std::tuple {dev_pv_y_histo.get(), histogram_pv_y, -2, 2},
                std::tuple {dev_pv_z_histo.get(), histogram_pv_z, -200, 200},
                std::tuple {dev_n_pvs_counter.get(), m_pvs}});
#endif
}

__global__ void pv_beamline_cleanup::pv_beamline_cleanup(
  pv_beamline_cleanup::Parameters parameters,
  gsl::span<unsigned> dev_n_pvs_counter,
  gsl::span<unsigned> dev_n_pvs_histo,
  gsl::span<unsigned> dev_pv_x_histo,
  gsl::span<unsigned> dev_pv_y_histo,
  gsl::span<unsigned> dev_pv_z_histo)
{

  __shared__ unsigned tmp_number_vertices[1];
  *tmp_number_vertices = 0;

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
      if (-2 < vertex1.position.x && vertex1.position.x < 2) {
        unsigned x_bin = std::floor(vertex1.position.x / 0.04f) + 50;
        ++dev_pv_x_histo[x_bin];
      }
      if (-2 < vertex1.position.y && vertex1.position.y < 2) {
        unsigned y_bin = std::floor(vertex1.position.y / 0.04f) + 50;
        ++dev_pv_y_histo[y_bin];
      }
      if (-200 < vertex1.position.z && vertex1.position.z < 200) {
        unsigned z_bin = std::floor(vertex1.position.z / 4) + 50;
        ++dev_pv_z_histo[z_bin];
      }
    }
  }
  __syncthreads();
  parameters.dev_number_of_multi_final_vertices[event_number] = *tmp_number_vertices;

  if (*tmp_number_vertices < 20) ++dev_n_pvs_histo[*tmp_number_vertices];
  dev_n_pvs_counter[0] += *tmp_number_vertices;
}
