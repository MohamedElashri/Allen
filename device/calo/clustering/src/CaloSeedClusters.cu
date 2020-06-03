#include <CaloSeedClusters.cuh>

__device__ void seed_clusters(CaloDigit const* digits,
                              CaloSeedCluster* clusters,
                              unsigned* num_clusters,
                              const CaloGeometry& geometry,
                              const uint16_t min_adc) {
  // Loop over all CellIDs.
  for (uint i = threadIdx.x; i < geometry.max_cellid; i += blockDim.x) {
    uint16_t adc = digits[i].adc;
    if (adc == 0) {
      continue;
    }
    uint16_t* neighbors = &(geometry.neighbors[i * Calo::Constants::max_neighbours]);
    bool is_max = true;
    for (uint n = 0; n < Calo::Constants::max_neighbours; n++) {
      is_max = is_max && (adc > digits[neighbors[n]].adc);
    }
    if (is_max && digits[i].adc > min_adc) {
      auto id = atomicAdd(num_clusters, 1);
      clusters[id] = CaloSeedCluster(i, digits[i].adc, geometry.getX(i), geometry.getY(i));
    }
  }
}

__global__ void calo_seed_clusters::calo_seed_clusters(
  calo_seed_clusters::Parameters parameters,
  const char* raw_ecal_geometry,
  const char* raw_hcal_geometry,
  const uint16_t ecal_min_adc,
  const uint16_t hcal_min_adc)
{
  unsigned const event_number = blockIdx.x;

  // Get geometry.
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry, Calo::Constants::ecal_max_cellid);
  auto hcal_geometry = CaloGeometry(raw_hcal_geometry, Calo::Constants::hcal_max_cellid);

  // ECal
  seed_clusters(parameters.dev_ecal_digits + (event_number * ecal_geometry.max_cellid),
                parameters.dev_ecal_seed_clusters + event_number,
                parameters.dev_ecal_num_clusters + event_number,
                ecal_geometry, ecal_min_adc);

  // HCal
  seed_clusters(parameters.dev_hcal_digits + (event_number * hcal_geometry.max_cellid),
                parameters.dev_hcal_seed_clusters + event_number,
                parameters.dev_hcal_num_clusters + event_number,
                hcal_geometry, hcal_min_adc);
}

void calo_seed_clusters::calo_seed_clusters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  auto const n_events = first<host_number_of_selected_events_t>(arguments);
  set_size<dev_ecal_num_clusters_t>(arguments, n_events);
  set_size<dev_hcal_num_clusters_t>(arguments, n_events);

  // TODO: get this from the geometry too
  set_size<dev_ecal_seed_clusters_t>(arguments, Calo::Constants::ecal_max_cells * n_events);
  set_size<dev_hcal_seed_clusters_t>(arguments, Calo::Constants::hcal_max_cells * n_events);
}

void calo_seed_clusters::calo_seed_clusters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  HostBuffers&,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  initialize<dev_ecal_num_clusters_t>(arguments, 0, cuda_stream);
  initialize<dev_hcal_num_clusters_t>(arguments, 0, cuda_stream);

  // Find local maxima.
  global_function(calo_seed_clusters)(
    dim3(first<host_number_of_selected_events_t>(arguments)), dim3(property<block_dim_x_t>().get()), cuda_stream)(
    arguments, constants.dev_ecal_geometry, constants.dev_hcal_geometry,
    property<ecal_min_adc_t>().get(), property<hcal_min_adc_t>().get());
}
