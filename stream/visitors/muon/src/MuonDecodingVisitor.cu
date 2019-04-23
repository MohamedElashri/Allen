#include "SequenceVisitor.cuh"
#include "MuonDecoding.cuh"
#include "MuonRawToHitsDecoding.h"

template<>
void SequenceVisitor::set_arguments_size<muon_decoding_t>(
    muon_decoding_t::arguments_t arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) {
  arguments.set_size<dev_muon_hits>(runtime_options.number_of_events);
}

template<>
void SequenceVisitor::visit<muon_decoding_t>(
    muon_decoding_t& state,
    const muon_decoding_t::arguments_t& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) {
  std::vector<Muon::HitsSoA> muon_hits_events(runtime_options.number_of_events);
  muonRawToHitsDecode(runtime_options.host_muon_events, runtime_options.host_muon_event_offsets, runtime_options.host_muon_events_size,
                      runtime_options.host_muon_event_offsets_size, muon_hits_events);

  cudaCheck(cudaMemcpyAsync(
      arguments.offset<dev_muon_hits>(),
      muon_hits_events.data(),
      runtime_options.number_of_events * sizeof(Muon::HitsSoA),
      cudaMemcpyHostToDevice,
      cuda_stream
  ));

  state.set_opts(dim3(1), dim3(1), cuda_stream);
  state.set_arguments(arguments.offset<dev_muon_hits>());
  state.invoke();

}
