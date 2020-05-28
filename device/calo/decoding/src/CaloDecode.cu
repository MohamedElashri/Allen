#include <MEPTools.h>
#include <CaloDecode.cuh>

// TODO thinks about blocks/threads etc. 1 block per fragment might be best for coalesced memory acces.

template<typename Event>
__device__ void decode(
  const char* event_data,
  const uint32_t* offsets,
  const unsigned* event_list,
  CaloDigit* digits,
  const CaloGeometry& geometry)
{
  const auto event_number = blockIdx.x;

  const uint16_t coding_numbers[6] = {
    0xF,
    8,
    4, // 4-bit coding values.
    0xFFF,
    256,
    12 // 12-bit coding values.
  };

  const auto selected_event_number = event_list[event_number];

  auto raw_event = Event {event_data, offsets};
  for (auto bank_number = threadIdx.x; bank_number < raw_event.number_of_raw_banks; bank_number += blockDim.x) {
    auto raw_bank = raw_event.bank(selected_event_number, bank_number);
    unsigned offset = 0; // To skip the source ID.
    int card = 0;
    // Loop over all cards in this raw bank.
    while (offset < raw_bank.size) {
      raw_bank.update(offset);
      uint64_t cur_data = ((uint64_t) raw_bank.data[1] << 32) +
                          raw_bank.data[0]; // Use 64 bit integers in case of 12 bits coding at border regions.
      int offset = 0;
      int item = 0; // Have to use an item count instead of pointer because of "misaligned address" bug.
      for (auto hit = 0; hit < CARD_CHANNELS; hit++) {
        if (offset > 31) {
          offset -= 32;
          item++;
          cur_data = ((uint64_t) raw_bank.data[item + 1] << 32) + raw_bank.data[item];
        }
        uint16_t adc = 0;
        int coding = (raw_bank.pattern >> hit) & 0x1;

        // Retrieve adc.
        adc = ((cur_data >> offset) & coding_numbers[coding * 3]) -
              coding_numbers[coding * 3 + 1]; // TODO ask if this - is necessary as it results in negative adc.
        offset += coding_numbers[coding * 3 + 2];

        // Store cellid and adc in result array.
        uint16_t cellid = geometry.channels[(raw_bank.code - geometry.code_offset) * CARD_CHANNELS + hit];

        // Some cell IDs have an area of 3 without any neighbors etc. ignore these.
        if ((cellid >> 12) <= 2) {
          digits[event_number * geometry.max_cellid + cellid].adc = adc;
          digits[event_number * geometry.max_cellid + cellid].clustered_at_iteration = UNCLUSTERED;
        }

        // Determine where the next card will start.
        offset = (raw_bank.get_length() + 31) / 32;
        card++;
      }
    }
  }
}

__global__ void calo_decode::calo_decode(
  calo_decode::Parameters parameters,
  const char* raw_ecal_geometry,
  const char* raw_hcal_geometry)
{
  // ECal
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry, ECAL_MAX_CELLID);
  decode<CaloRawEvent>(
    parameters.dev_ecal_raw_input,
    parameters.dev_ecal_raw_input_offsets,
    parameters.dev_event_list,
    parameters.dev_ecal_digits,
    ecal_geometry);

  // HCal
  auto hcal_geometry = CaloGeometry(raw_hcal_geometry, HCAL_MAX_CELLID);
  decode<CaloRawEvent>(
    parameters.dev_hcal_raw_input,
    parameters.dev_hcal_raw_input_offsets,
    parameters.dev_event_list,
    parameters.dev_hcal_digits,
    hcal_geometry);
}

__global__ void calo_decode::calo_decode_mep(
  calo_decode::Parameters parameters,
  const char* raw_ecal_geometry,
  const char* raw_hcal_geometry)
{
  // ECal
  auto ecal_geometry = CaloGeometry {raw_ecal_geometry, ECAL_MAX_CELLID};
  decode<CaloMepEvent>(
    parameters.dev_ecal_raw_input,
    parameters.dev_ecal_raw_input_offsets,
    parameters.dev_event_list,
    parameters.dev_ecal_digits,
    ecal_geometry);

  // HCal
  auto hcal_geometry = CaloGeometry {raw_hcal_geometry, HCAL_MAX_CELLID};
  decode<CaloMepEvent>(
    parameters.dev_hcal_raw_input,
    parameters.dev_hcal_raw_input_offsets,
    parameters.dev_event_list,
    parameters.dev_hcal_digits,
    hcal_geometry);
}

void calo_decode::calo_decode_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_ecal_digits_t>(arguments, ECAL_MAX_CELLID * first<host_number_of_selected_events_t>(arguments));
  set_size<dev_hcal_digits_t>(arguments, HCAL_MAX_CELLID * first<host_number_of_selected_events_t>(arguments));
}

void calo_decode::calo_decode_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers&,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  initialize<dev_ecal_digits_t>(arguments, 0, cuda_stream);
  initialize<dev_hcal_digits_t>(arguments, 0, cuda_stream);

  if (runtime_options.mep_layout) {
    global_function(calo_decode_mep)(
      first<host_number_of_selected_events_t>(arguments), property<block_dim_x_t>().get(), cuda_stream)(
      arguments,
      constants.dev_ecal_geometry,
      constants.dev_hcal_geometry);
  }
  else {
    global_function(calo_decode)(
      first<host_number_of_selected_events_t>(arguments), property<block_dim_x_t>().get(), cuda_stream)(
      arguments,
      constants.dev_ecal_geometry,
      constants.dev_hcal_geometry);
  }
}
