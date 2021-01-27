#include <MEPTools.h>
#include <CaloConstants.cuh>
#include <CaloCountDigits.cuh>

// TODO thinks about blocks/threads etc. 1 block per fragment might be best for coalesced memory acces.

__device__ void offsets(unsigned const* event_list,
                        unsigned const n_events,
                        unsigned* number_of_digits,
                        CaloGeometry const& geometry)
{
  for (unsigned idx = threadIdx.x; idx < n_events; idx += blockDim.x) {
    auto event_number = event_list[idx];
    number_of_digits[event_number] = geometry.max_index;
  }
}

__global__ void calo_count_digits::calo_count_digits(
  calo_count_digits::Parameters parameters,
  const char* raw_ecal_geometry,
  const char* raw_hcal_geometry)
{
  // ECal
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry);
  offsets(parameters.dev_event_list,
          parameters.dev_number_of_events[0],
          parameters.dev_ecal_num_digits,
          ecal_geometry);

  // HCal
  auto hcal_geometry = CaloGeometry(raw_hcal_geometry);
  offsets(parameters.dev_event_list,
          parameters.dev_number_of_events[0],
          parameters.dev_hcal_num_digits,
          hcal_geometry);

}

void calo_count_digits::calo_count_digits_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_ecal_num_digits_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_hcal_num_digits_t>(arguments, first<host_number_of_events_t>(arguments));
}

void calo_count_digits::calo_count_digits_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  HostBuffers&,
  const Allen::Context& context) const
{
  initialize<dev_ecal_num_digits_t>(arguments, 0, context);
  initialize<dev_hcal_num_digits_t>(arguments, 0, context);

  global_function(calo_count_digits)(
    dim3(1), dim3(property<block_dim_x_t>().get()), context)(
    arguments, constants.dev_ecal_geometry, constants.dev_hcal_geometry);
  }
