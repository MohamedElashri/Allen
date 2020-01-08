#include "PrepareRawBanks.cuh"

void prepare_raw_banks_t::set_arguments_size(
  ArgumentRefManager<Arguments> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  int n_hlt1_lines = Hlt1::Hlt1Lines::End;
  arguments.set_size<dev_dec_reports>((2 + n_hlt1_lines) * host_buffers.host_number_of_selected_events[0]);
  arguments.set_size<dev_number_of_passing_events>(1);
  arguments.set_size<dev_passing_event_list>(host_buffers.host_number_of_selected_events[0]);
}

void prepare_raw_banks_t::operator()(
  const ArgumentRefManager<Arguments>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  // Initialize number of events passing Hlt1.
  cudaCheck(cudaMemsetAsync(
    offset<dev_number_of_passing_events_t>(arguments),
    0,
    sizeof(uint),
    cuda_stream));

  cudaCheck(cudaMemsetAsync(
    offset<dev_dec_reports_t>(arguments),
    0,
    size<dev_dec_reports_t>(arguments),
    cuda_stream));
  
  function(dim3(host_buffers.host_number_of_selected_events[0]), block_dimension(), cuda_stream)(
    offset<dev_atomics_scifi_t>(arguments),
    offset<dev_sv_offsets_t>(arguments),
    offset<dev_one_track_results_t>(arguments),
    offset<dev_two_track_results_t>(arguments),
    offset<dev_single_muon_results_t>(arguments),
    offset<dev_disp_dimuon_results_t>(arguments),
    offset<dev_high_mass_dimuon_results_t>(arguments),
    offset<dev_dec_reports_t>(arguments),
    offset<dev_number_of_passing_events_t>(arguments),
    offset<dev_passing_event_list_t>(arguments));

  // Copy raw bank data.
  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_dec_reports,
    offset<dev_dec_reports_t>(arguments),
    size<dev_dec_reports_t>(arguments),
    cudaMemcpyDeviceToHost,
    cuda_stream));

  // Copy list of passing events.
  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_number_of_passing_events,
    offset<dev_number_of_passing_events_t>(arguments),
    size<dev_number_of_passing_events_t>(arguments),
    cudaMemcpyDeviceToHost,
    cuda_stream));
  
  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_passing_event_list,
    offset<dev_passing_event_list_t>(arguments),
    size<dev_passing_event_list_t>(arguments),
    cudaMemcpyDeviceToHost,
    cuda_stream));
}

__global__ void prepare_raw_banks(
  const uint* dev_atomics_scifi,
  const uint* dev_sv_offsets,
  const bool* dev_one_track_results,
  const bool* dev_two_track_results,
  const bool* dev_single_muon_results,
  const bool* dev_disp_dimuon_results,
  const bool* dev_high_mass_dimuon_results,
  uint32_t* dev_dec_reports,
  uint* number_of_passing_events,
  uint* event_list)
{

  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // Tracks.
  const uint* event_tracks_offsets = dev_atomics_scifi + number_of_events;
  const bool* event_one_track_results = dev_one_track_results + event_tracks_offsets[event_number];
  const bool* event_single_muon_results = dev_single_muon_results + event_tracks_offsets[event_number];
  const int n_tracks_event = dev_atomics_scifi[event_number];

  // Vertices.
  const bool* event_two_track_results = dev_two_track_results + dev_sv_offsets[event_number];
  const bool* event_disp_dimuon_results = dev_disp_dimuon_results + dev_sv_offsets[event_number];
  const bool* event_high_mass_dimuon_results = dev_high_mass_dimuon_results + dev_sv_offsets[event_number];
  const int n_vertices_event = dev_sv_offsets[event_number + 1] - dev_sv_offsets[event_number];

  // Dec reports.
  const int n_hlt1_lines = Hlt1::Hlt1Lines::End;
  uint32_t* event_dec_reports = dev_dec_reports + (2 + n_hlt1_lines) * event_number;

  // Set track decisions.
  uint32_t dec_mask = HltDecReport::decReportMasks::decisionMask;
  for (int i_track = threadIdx.x; i_track < n_tracks_event; i_track += blockDim.x) {    
    // One track.
    uint32_t dec = ((event_one_track_results[i_track] ? 1 : 0) & dec_mask);
    atomicOr(event_dec_reports + 2 + Hlt1::Hlt1Lines::OneTrackMVA, dec);
    // Single muon decision.
    dec = ((event_single_muon_results[i_track] ? 1 : 0) & dec_mask);
    atomicOr(event_dec_reports + 2 + Hlt1::Hlt1Lines::SingleMuon, dec);
  }
  __syncthreads();
  
  // Set vertex decisions.
  for (int i_sv = threadIdx.x; i_sv < n_vertices_event; i_sv += blockDim.x) {
    // Two track.
    uint32_t dec = ((event_two_track_results[i_sv] ? 1 : 0) & dec_mask);
    atomicOr(event_dec_reports + 2 + Hlt1::Hlt1Lines::TwoTrackMVA, dec);
    // Displaced dimuon.
    dec = ((event_disp_dimuon_results[i_sv] ? 1 : 0) & dec_mask);
    atomicOr(event_dec_reports + 2 + Hlt1::Hlt1Lines::DisplacedDiMuon, dec);
    // High mass dimuon.
    dec = ((event_high_mass_dimuon_results[i_sv] ? 1 : 0) & dec_mask);
    atomicOr(event_dec_reports + 2 + Hlt1::Hlt1Lines::HighMassDiMuon, dec);
  }
  __syncthreads();

  // If any line is passed, add to selected events and create the rest of the DecReport.
  if (threadIdx.x == 0) {
    
    // Return if event has not passed.
    bool pass = false;
    for (int i_line = 0; i_line < Hlt1::Hlt1Lines::End; i_line++) {
      pass = pass || ((event_dec_reports[2 + i_line] & dec_mask) == (1 & dec_mask));
      if (pass) {
        break;
      }
    }
    if (!pass) return;

    const uint n_pass = atomicAdd(number_of_passing_events, 1);
    event_list[n_pass] = event_number;
    // Create the rest of the dec report.
    event_dec_reports[0] = Hlt1::TCK;
    event_dec_reports[1] = Hlt1::taskID;
    for (uint i_line = 0; i_line < Hlt1::Hlt1Lines::End; i_line++) {
      HltDecReport dec_report;
      dec_report.setDecision(false);
      // TODO: These are all placeholder values for now.
      dec_report.setErrorBits(0);
      dec_report.setNumberOfCandidates(1);
      dec_report.setIntDecisionID(i_line);
      dec_report.setExecutionStage(1);
      // Set the final dec report.
      event_dec_reports[2 + i_line] |= dec_report.getDecReport();
    }
  }
  
}
