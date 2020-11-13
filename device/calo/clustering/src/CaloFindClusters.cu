#include <CaloCluster.cuh>
#include <CaloFindClusters.cuh>
#include <iostream>

__device__ void simple_clusters(CaloDigit const* digits,
                                CaloSeedCluster const* seed_clusters,
                                CaloCluster* clusters,
                                unsigned const num_clusters,
                                const CaloGeometry& calo) {
  for (unsigned c = threadIdx.x; c < num_clusters; c += blockDim.x) {
    auto const& seed_cluster = seed_clusters[c];
    auto& cluster = clusters[c];
    cluster.center_id = seed_cluster.id;
    cluster.e = calo.pedestal + seed_cluster.adc * calo.gain[seed_cluster.id];
    cluster.x = seed_cluster.x;
    cluster.y = seed_cluster.y;

    uint16_t const* neighbors = &(calo.neighbors[seed_cluster.id * Calo::Constants::max_neighbours]);
    for (uint16_t n = 0; n < Calo::Constants::max_neighbours; n++) {
      auto const n_id = neighbors[n];
      int16_t adc = digits[n_id].adc;
      if (n_id != 0 && (adc != SHRT_MAX)) {
        cluster.e += calo.pedestal + adc * calo.gain[n_id];
        cluster.digits[n] = n_id;
      } else {
        cluster.digits[n] = 0;
      }
    }

    // Code to update position, double check
    // for (uint16_t n = 0; n < Calo::Constants::max_neighbours; n++) {
    //   auto const n_id = neighbors[n];
    //   if (n_id != 0 && ((auto const adc = digits[n_id].adc) != SHRT_MAX)) {
    //     float const adc_frac = float(adc) / float(cluster.e);
    //     cluster.x += adc_frac * (geometry.getX(n_id) - seed_cluster.x);
    //     cluster.y += adc_frac * (geometry.getY(n_id) - seed_cluster.y);
    //   }
    // }
  }
}

__global__ void calo_find_clusters::calo_find_clusters(
  calo_find_clusters::Parameters parameters,
  const char* raw_ecal_geometry,
  const char* raw_hcal_geometry,
  const unsigned)
{
  // Get proper geometry.
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry);
  auto hcal_geometry = CaloGeometry(raw_hcal_geometry);

  unsigned const event_number = parameters.dev_event_list[blockIdx.x];

  // Build simple 3x3 clusters from seed clusters
  // Ecal
  unsigned const ecal_offset = parameters.dev_ecal_cluster_offsets[event_number];
  unsigned const ecal_num_clusters = parameters.dev_ecal_cluster_offsets[event_number + 1] - ecal_offset;
  simple_clusters(parameters.dev_ecal_digits + (event_number * ecal_geometry.max_index),
                  parameters.dev_ecal_seed_clusters + ecal_geometry.max_index * event_number,
                  parameters.dev_ecal_clusters + ecal_offset,
                  ecal_num_clusters, ecal_geometry);

  // Hcal
  unsigned const hcal_offset = parameters.dev_hcal_cluster_offsets[event_number];
  unsigned const hcal_num_clusters = parameters.dev_hcal_cluster_offsets[event_number + 1] - hcal_offset;
  simple_clusters(parameters.dev_hcal_digits + (event_number * hcal_geometry.max_index),
                  parameters.dev_hcal_seed_clusters + hcal_geometry.max_index * event_number,
                  parameters.dev_hcal_clusters + ecal_offset,
                  hcal_num_clusters, hcal_geometry);

}

void calo_find_clusters::calo_find_clusters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  auto const n_ecal_clusters = first<host_ecal_number_of_clusters_t>(arguments);
  set_size<dev_ecal_digits_clusters_t>(arguments, n_ecal_clusters);
  set_size<dev_ecal_clusters_t>(arguments, n_ecal_clusters);

  auto const n_hcal_clusters = first<host_hcal_number_of_clusters_t>(arguments);
  set_size<dev_hcal_digits_clusters_t>(arguments, n_hcal_clusters);
  set_size<dev_hcal_clusters_t>(arguments, n_hcal_clusters);
}


__host__ void calo_find_clusters::calo_find_clusters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  HostBuffers&,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  // Find clusters.
  global_function(calo_find_clusters)(
    dim3(size<dev_event_list_t>(arguments)), dim3(property<block_dim_x_t>().get()), cuda_stream)(
    arguments,
    constants.dev_ecal_geometry,
    constants.dev_hcal_geometry,
    property<iterations_t>().get());

  if (runtime_options.do_check) {
    safe_assign_to_host_buffer<dev_ecal_cluster_offsets_t>(host_buffers.host_ecal_cluster_offsets, arguments, cuda_stream);
    safe_assign_to_host_buffer<dev_hcal_cluster_offsets_t>(host_buffers.host_hcal_cluster_offsets, arguments, cuda_stream);
    safe_assign_to_host_buffer<dev_ecal_clusters_t>(host_buffers.host_ecal_clusters, arguments, cuda_stream);
    safe_assign_to_host_buffer<dev_hcal_clusters_t>(host_buffers.host_hcal_clusters, arguments, cuda_stream);
  }
}
