#include "SequenceVisitor.cuh"
#include "MuonRawToHitsDecoding.h"

template<>
void SequenceVisitor::set_arguments_size<muon_raw_to_hits_decoding_t>(
    muon_raw_to_hits_decoding::arguments_t arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers)
{}

template<>
void SequenceVisitor::visit<muon_raw_to_hits_decoding_t>(
    muon_raw_to_hits_decoding_t& state,
    const is_muon_t::arguments_t& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event)
{
  
}
