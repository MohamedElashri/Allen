#include <MEPTools.h>
#include <CaloConstants.cuh>
#include <CaloDecode.cuh>

#include <iomanip>

// TODO thinks about blocks/threads etc. 1 block per fragment might be best for coalesced memory acces.

template<typename Event>
__device__ void decode(const char* event_data, const uint32_t* offsets,
                       const unsigned* event_list,
                       CaloDigit* digits,
                       const CaloGeometry& geometry)
{
  unsigned const event_number = event_list[blockIdx.x];

  auto raw_event = Event{event_data, offsets};
  for (auto bank_number = threadIdx.x; bank_number < raw_event.number_of_raw_banks; bank_number += blockDim.x) {
    auto raw_bank = raw_event.bank(event_number, bank_number);
    while (raw_bank.data < raw_bank.end) {
      uint32_t word = *raw_bank.data;
      uint16_t trig_size = word & 0x7F;
      uint16_t code = ( word >> 14 ) & 0x1FF;

      // Skip header and trigger words
      raw_bank.data += 1 + (trig_size + 3) / 4;

      // pattern bits
      unsigned int pattern = *raw_bank.data;
      // Loop over all cards in this front-env sub-bank.
      uint32_t last_data =  *(raw_bank.data + 1);
      raw_bank.data += 2;

      int16_t offset = 0;

      for ( unsigned int bit_num = 0; 32 > bit_num; ++bit_num ) {
        if ( 31 < offset ) {
          offset -= 32;
          last_data = *raw_bank.data;
          raw_bank.data += 1;
        }
        int adc;
        if ( 0 == ( pattern & ( 1 << bit_num ) ) ) { //.. short coding
          adc = ( ( last_data >> offset ) & 0xF ) - 8;
          offset += 4;
        } else {
          adc = ( ( last_data >> offset ) & 0xFFF );
          if ( 24 == offset ) adc &= 0xFF;
          if ( 28 == offset ) adc &= 0xF; //== clean-up extra bits
          offset += 12;
          if ( 32 < offset ) { //.. get the extra bits on next word
            last_data = *raw_bank.data;
            raw_bank.data += 1;
            offset -= 32;
            int temp = ( last_data << ( 12 - offset ) ) & 0xFFF;
            adc += temp;
          }
          adc -= 256;
         }

        uint16_t index = geometry.channels[(code - geometry.code_offset) * Calo::Constants::card_channels + bit_num];
        // Ignore cells with invalid indices
        if (index < geometry.max_index) {
          digits[event_number * geometry.max_index + index].adc = adc;
        }
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
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry);
  decode<CaloRawEvent>(parameters.dev_ecal_raw_input,
                       parameters.dev_ecal_raw_input_offsets,
                       parameters.dev_event_list,
                       parameters.dev_ecal_digits,
                       ecal_geometry);

  // HCal
  auto hcal_geometry = CaloGeometry(raw_hcal_geometry);
  decode<CaloRawEvent>(parameters.dev_hcal_raw_input,
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
  auto ecal_geometry = CaloGeometry{raw_ecal_geometry};
  decode<CaloMepEvent>(parameters.dev_ecal_raw_input,
                       parameters.dev_ecal_raw_input_offsets,
                       parameters.dev_event_list,
                       parameters.dev_ecal_digits,
                       ecal_geometry);

  // HCal
  auto hcal_geometry = CaloGeometry{raw_hcal_geometry};
  decode<CaloMepEvent>(parameters.dev_hcal_raw_input,
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
  set_size<dev_ecal_digits_t>(arguments, Calo::Constants::ecal_max_index * first<host_number_of_selected_events_t>(arguments));
  set_size<dev_hcal_digits_t>(arguments, Calo::Constants::hcal_max_index * first<host_number_of_selected_events_t>(arguments));
}

void calo_decode::calo_decode_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers&,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  initialize<dev_ecal_digits_t>(arguments, SHRT_MAX, cuda_stream);
  initialize<dev_hcal_digits_t>(arguments, SHRT_MAX, cuda_stream);

  if (runtime_options.mep_layout) {
    global_function(calo_decode_mep)(
      dim3(size<dev_event_list_t>(arguments)), dim3(property<block_dim_x_t>().get()), cuda_stream)(
      arguments, constants.dev_ecal_geometry, constants.dev_hcal_geometry);
  }
  else {
    global_function(calo_decode)(
      dim3(size<dev_event_list_t>(arguments)), dim3(property<block_dim_x_t>().get()), cuda_stream)(
      arguments, constants.dev_ecal_geometry, constants.dev_hcal_geometry);
  }
}
