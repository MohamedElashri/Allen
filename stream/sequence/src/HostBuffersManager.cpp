#include "HostBuffersManager.cuh"
#include "HostBuffers.cuh"

#include "HltDecReport.cuh"
#include "HltSelReport.cuh"
#include "RawBanksDefinitions.cuh"
#include "LineInfo.cuh"

#include "Logger.h"

void HostBuffersManager::init(size_t nBuffers)
{
  host_buffers.reserve(nBuffers);
  for (size_t i = 0; i < nBuffers; ++i) {
    host_buffers.push_back(new HostBuffers());
    host_buffers.back()->reserve(max_events, check, m_number_of_hlt1_lines);
    buffer_statuses.push_back(BufferStatus::Empty);
    empty_buffers.push(i);
  }
}

size_t HostBuffersManager::assignBufferToFill()
{
  if (empty_buffers.empty()) {
    warning_cout << "No empty buffers available" << std::endl;
    warning_cout << "Adding new buffers" << std::endl;
    host_buffers.push_back(new HostBuffers());
    host_buffers.back()->reserve(max_events, check, m_number_of_hlt1_lines);
    buffer_statuses.push_back(BufferStatus::Filling);
    return host_buffers.size() - 1;
  }

  auto b = empty_buffers.front();
  empty_buffers.pop();

  buffer_statuses[b] = BufferStatus::Filling;
  return b;
}

size_t HostBuffersManager::assignBufferToProcess()
{
  // FIXME required until nvcc supports C++17
  // ideally, this fuction would return a std::optional<size_t>
  if (filled_buffers.empty()) return SIZE_MAX;

  auto b = filled_buffers.front();
  filled_buffers.pop();

  buffer_statuses[b] = BufferStatus::Processing;
  return b;
}

void HostBuffersManager::returnBufferFilled(size_t b)
{
  buffer_statuses[b] = BufferStatus::Filled;
  filled_buffers.push(b);
}

void HostBuffersManager::returnBufferUnfilled(size_t b)
{
  buffer_statuses[b] = BufferStatus::Empty;
  empty_buffers.push(b);
}

void HostBuffersManager::returnBufferProcessed(size_t b)
{
  // buffer must be both processed (monitoring) and written (I/O)
  // if I/O is already finished then mark "empty"
  // otherwise, mark "processed" and wait for I/O
  if (buffer_statuses[b] == BufferStatus::Written) {
    buffer_statuses[b] = BufferStatus::Empty;
    empty_buffers.push(b);
  }
  else {
    buffer_statuses[b] = BufferStatus::Processed;
  }
}

void HostBuffersManager::returnBufferWritten(size_t b)
{
  // buffer must be both processed (monitoring) and written (I/O)
  // if monitoring is already finished then mark "empty"
  // otherwise, mark "written" and wait for I/O
  if (buffer_statuses[b] == BufferStatus::Processed) {
    buffer_statuses[b] = BufferStatus::Empty;
    empty_buffers.push(b);
  }
  else {
    buffer_statuses[b] = BufferStatus::Written;
  }
}

void HostBuffersManager::writeSingleEventPassthrough(const size_t b)
{
  if (b >= host_buffers.size()) {
    error_cout << "Buffer index " << b << " is larger than the number of available buffers: " << host_buffers.size()
               << std::endl;
    return;
  }
  auto buf = host_buffers[b];

  buf->host_number_of_passing_events[0] = 1u;
  buf->host_passing_event_list[0] = 0u;
  // create DecReport
  buf->host_dec_reports[0] = Hlt1::TCK;
  buf->host_dec_reports[1] = Hlt1::taskID;
  for (uint i_line = 0; i_line < m_number_of_hlt1_lines; i_line++) {
    HltDecReport dec_report;
    dec_report.setDecision(false);
    dec_report.setErrorBits(0);
    dec_report.setNumberOfCandidates(0);
    dec_report.setIntDecisionID(i_line);
    dec_report.setExecutionStage(1);
    if (i_line == m_passthrough_line) {
      dec_report.setDecision(true);
      dec_report.setNumberOfCandidates(1);
    }
    buf->host_dec_reports[i_line + 2] = dec_report.getDecReport();
  }
  // create SelReport
  HltSelRepRawBank(buf->host_sel_rep_raw_banks, HltSelRepRawBank::kHeaderSize);
  buf->host_sel_rep_offsets[0] = 0u;
  buf->host_sel_rep_offsets[1] = HltSelRepRawBank::kHeaderSize;
  returnBufferFilled(b);
}

std::tuple<gsl::span<uint const>, gsl::span<uint32_t const>, gsl::span<uint32_t const>, gsl::span<uint const>>
HostBuffersManager::getBufferOutputData(size_t b)
{
  if (b > host_buffers.size()) return {};

  HostBuffers* buf = host_buffers.at(b);
  auto const n_passing = buf->host_number_of_passing_events[0];
  const uint sel_rep_buf_size = buf->host_sel_rep_offsets[n_passing];
  const uint dec_rep_buf_size = (m_number_of_hlt1_lines + 2) * max_events;

  gsl::span<uint const> passing_event_list {buf->host_passing_event_list, n_passing};
  gsl::span<uint32_t const> dec_reports {buf->host_dec_reports, dec_rep_buf_size};
  gsl::span<uint32_t const> sel_reports {buf->host_sel_rep_raw_banks, sel_rep_buf_size};
  gsl::span<uint const> sel_report_offsets {buf->host_sel_rep_offsets, n_passing + 1};
  return {passing_event_list, dec_reports, sel_reports, sel_report_offsets};
}

void HostBuffersManager::printStatus() const
{
  info_cout << host_buffers.size() << " buffers; " << empty_buffers.size() << " empty; " << filled_buffers.size()
            << " filled." << std::endl;
}
