/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <iostream>

#include <cstdio>
#include <cstring>
#include <unistd.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <read_mdf.hpp>
#include <write_mdf.hpp>
#include <mdf_header.hpp>
#include <raw_helpers.hpp>

#include <InputProvider.h>
#include <OutputHandler.h>
#include <RoutingBitsDefinition.h>
#include <HltConstants.cuh>
#include <TAE.h>
#include <Store.cuh>

namespace {
  // Size of the MDF header
  auto const header_size = LHCb::MDFHeader::sizeOf(Allen::mdf_header_version);
  // size of the RoutingBits RawBank
  const unsigned routing_bits_size = RoutingBitsDefinition::n_words * sizeof(uint32_t);
} // namespace

struct HLT1Outputs {

  HLT1Outputs(Allen::Store::PersistentStore const& store);

  gsl::span<bool const> selected_events;
  gsl::span<unsigned const> dec_reports;
  gsl::span<unsigned const> lumi_summaries;
  gsl::span<unsigned const> lumi_summary_offsets;
  gsl::span<unsigned const> routing_bits;
  gsl::span<unsigned const> sel_reports;
  gsl::span<unsigned const> sel_reports_offsets;
  gsl::span<TAE::TAEEvent const> tae_events;
};

HLT1Outputs::HLT1Outputs(Allen::Store::PersistentStore const& store)
{
  selected_events = store.try_at<bool>("global_decision__host_global_decision_t").value_or(gsl::span<bool const> {});
  dec_reports = store.try_at<unsigned>("dec_reporter__host_dec_reports_t").value_or(gsl::span<unsigned const> {});
  lumi_summaries =
    store.try_at<unsigned>("make_lumi_summary__host_lumi_summaries_t").value_or(gsl::span<unsigned const> {});
  lumi_summary_offsets =
    store.try_at<unsigned>("make_lumi_summary__host_lumi_summary_offsets_t").value_or(gsl::span<unsigned const> {});
  routing_bits =
    store.try_at<unsigned>("host_routingbits_writer__host_routingbits_t").value_or(gsl::span<unsigned const> {});
  sel_reports = store.try_at<unsigned>("make_selreps__host_sel_reports_t").value_or(gsl::span<unsigned const> {});
  sel_reports_offsets =
    store.try_at<unsigned>("make_selreps__host_selrep_offsets_t").value_or(gsl::span<unsigned const> {});
  tae_events = store.try_at<TAE::TAEEvent>("tae_filter__host_tae_events_t").value_or(gsl::span<TAE::TAEEvent const> {});

  if (selected_events.empty())
    throw StrException {
      "Cannot output events without selected events. Ensure the global decision algorithm is part of the sequence."};
  if (dec_reports.empty())
    throw StrException {
      "Cannot output events without dec reports. Ensure the dec reports writer is part of the sequence."};
  if (routing_bits.empty())
    throw StrException {
      "Cannot output events without routing bits. Ensure the routing bits writer is part of the sequence."};
}

std::tuple<bool, size_t> OutputHandler::output_selected_events(
  size_t const thread_id,
  size_t const slice_index,
  size_t const start_event,
  Allen::Store::PersistentStore const& store)
{
  auto [success, n_output] = output_single_events(thread_id, slice_index, start_event, store);
  if (!success) return {success, n_output};

  size_t n_tae = 0;
  std::tie(success, n_tae) = output_tae_events(thread_id, slice_index, start_event, store);
  return {success, n_output + n_tae};
}

std::tuple<bool, size_t> OutputHandler::output_single_events(
  size_t const thread_id,
  size_t const slice_index,
  size_t const start_event,
  Allen::Store::PersistentStore const& store)
{
  HLT1Outputs outputs {store};

  // If TAE events should to be output as batches, that's done
  // separately in output_tae_event, so skip them here
  gsl::span<TAE::TAEEvent const> tae_events;
  bool output_tae = !outputs.tae_events.empty();
  if (output_tae) {
    tae_events = outputs.tae_events;
  }
  std::vector<unsigned> selected_events;
  selected_events.reserve(outputs.selected_events.size());
  size_t tae_index = 0;
  for (unsigned i = 0; i < outputs.selected_events.size(); ++i) {
    if (outputs.selected_events[i] && (!output_tae || i != tae_events[tae_index].central)) {
      // selected_events is passed to the InputProvider to get the
      // event sizes. The InputProvider doesn't know about slice
      // splitting, so we have to offset by start_event here.
      auto const event_number = i + start_event;
      selected_events.push_back(event_number);
    }
    if (output_tae && tae_index < (tae_events.size() - 1) && tae_events[tae_index].central == i) {
      ++tae_index;
    }
  }

  auto const n_events = static_cast<size_t>(selected_events.size());
  if (n_events == 0) return {true, 0};

  // sizes will contain the total size of all input banks in the event
  auto const& sizes = event_sizes(thread_id, slice_index, store, selected_events, start_event);
  auto event_ids = m_input_provider->event_ids(slice_index);

  bool output_success = true;

  // Output regular events in batches
  size_t n_output = 0;
  size_t n_batches = n_events / m_output_batch_size + (n_events % m_output_batch_size != 0);

#ifndef STANDALONE
  if (m_nbatches) (*m_nbatches) += n_batches;
#endif

  for (size_t i_batch = 0; i_batch < n_batches && output_success; ++i_batch) {

    size_t batch_buffer_size = 0;
    size_t output_event_offset = 0;
    size_t batch_size = std::min(m_output_batch_size, n_events - n_output);

#ifndef STANDALONE
    if (m_noutput) (*m_noutput) += batch_size;
    if (m_batch_size) (*m_batch_size) += batch_size;
#endif

    for (size_t i = n_output; i < n_output + batch_size; ++i) {
      batch_buffer_size += sizes.input[i] + sizes.hlt[i] + header_size;
    }

    auto batch_span = buffer(thread_id, batch_buffer_size, batch_size);

    // In case output was cancelled
    if (batch_span.empty()) return {false, 0};

    for (size_t i = n_output; i < n_output + batch_size; ++i) {

      // The event number is constructed to index into a batch. The 0th
      // event of a batch is start_event in a slice, so we subtract
      // start_event that was added to selected_events to have a direct
      // index into the batch again.
      auto const event_number = selected_events[i] - start_event;

      // event sizes are indexed in the same way as selected_events
      size_t output_event_size = header_size + sizes.input[i] + sizes.hlt[i];

      // The memory range in the output buffer for this event
      auto event_span = batch_span.subspan(output_event_offset, output_event_size);

      // WORKING, fix changed type of members of HLT1Outputs and avoid
      // "used uninitialized warnings". Probably best to add a check
      // for all of the ones we assume are present.

      // Add the MDF header
      auto* header = add_mdf_header(
        event_span,
        static_cast<unsigned int>(std::get<0>(event_ids[event_number + start_event])),
        outputs.routing_bits.subspan(RoutingBitsDefinition::n_words * event_number, RoutingBitsDefinition::n_words));

      // Add the input banks and HLT1 banks to the event
      add_banks(
        store,
        slice_index,
        start_event,
        event_number,
        sizes.input[i],
        event_span.subspan(header_size, output_event_size - header_size));

      add_checksum(header, event_span);

      output_event_offset += output_event_size;
    }

    // FIXME do something if output failed
    auto output_success = write_buffer(thread_id);

    n_output += output_success ? batch_size : 0;
  }
  assert(n_events - n_output == 0);

  return {output_success, n_output};
}

std::tuple<bool, size_t> OutputHandler::output_tae_events(
  size_t const thread_id,
  size_t const slice_index,
  size_t const start_event,
  Allen::Store::PersistentStore const& store)
{
  HLT1Outputs outputs {store};

  // Main approach to adding TAE banks:
  // a) Output TAE events into a separate buffer
  // b) try to measure effect on throughout with buffer manager
  // c) optimize if needed by adding more threads, or including TAE
  //    events in the same buffers as the batches

  if (outputs.tae_events.empty()) return {true, 0};

  // The TAEHeader bank must be the first bank after the MDF header,
  // should by of type TAEHeader and have a body consisting of a
  // triplet of ints (nBx, offset, size); nBx starts at
  // -tae_half_window; the offset is with respect to the end of the
  // TAEHeader bank; and size is in bytes

  std::vector<unsigned> selected_events;
  std::vector<unsigned> tae_offsets;
  auto& tae_events = outputs.tae_events;
  selected_events.reserve(tae_events.size() * (2 * tae_events[0].half_window + 1));
  tae_offsets.reserve(tae_events.size());
  for (auto tae_event : tae_events) {
    tae_offsets.push_back(selected_events.size());
    for (unsigned event_number = tae_event.central - tae_event.half_window;
         event_number <= tae_event.central + tae_event.half_window;
         ++event_number) {
      // selected_events is passed to the InputProvider to get the
      // event sizes. The InputProvider doesn't know about slice
      // splitting, so we have to offset by start_event here.
      selected_events.push_back(event_number + start_event);
    }
  }

#ifndef STANDALONE
  if (m_ntae) (*m_ntae) += tae_events.size();
#endif

  auto event_ids = m_input_provider->event_ids(slice_index);

  auto& sizes = event_sizes(thread_id, slice_index, store, selected_events, start_event);

  auto tae_bank_size = [](unsigned half_window) { return (2 * half_window + 1) * 3 * sizeof(int); };

  size_t tae_buffer_size = 0;
  for (size_t tae_index = 0; tae_index < tae_events.size(); ++tae_index) {
    auto const& tae_event = tae_events[tae_index];
    auto const offset = tae_offsets[tae_index];
    size_t tae_size = header_size + bank_header_size + tae_bank_size(tae_event.half_window);
    for (unsigned sub_index = offset; sub_index < offset + 2 * tae_event.half_window + 1; ++sub_index) {
      tae_size += sizes.input[sub_index] + sizes.hlt[sub_index];
    }
    tae_buffer_size += tae_size;
    sizes.tae[tae_event.central] = tae_size;
  }

  auto tae_buffer = buffer(thread_id, tae_buffer_size, tae_events.size());

  size_t tae_output_offset = 0;
  for (size_t tae_index = 0; tae_index < tae_events.size(); ++tae_index) {
    auto const& tae_event = tae_events[tae_index];
    auto const offset = tae_offsets[tae_index];
    auto const tae_size = sizes.tae[tae_event.central];
    auto tae_span = tae_buffer.subspan(tae_output_offset, tae_size);

    auto header = add_mdf_header(
      tae_span,
      static_cast<unsigned int>(std::get<0>(event_ids[tae_event.central + start_event])),
      outputs.routing_bits.subspan(RoutingBitsDefinition::n_words * tae_event.central, RoutingBitsDefinition::n_words));

    // Build the header of the TAEHeader bank
    auto* tae_header = reinterpret_cast<LHCb::RawBank*>(&tae_span[0] + header_size);
    tae_header->setMagic();
    tae_header->setType(LHCb::RawBank::TAEHeader);
    tae_header->setVersion(0);
    tae_header->setSourceID(0);
    tae_header->setSize(tae_bank_size(tae_event.half_window));

    auto const preamble_size = header_size + tae_header->totalSize();
    auto* tae_header_payload = tae_header->begin<int>();

    // Shrink tae_span to the combined size of the sub-events
    auto payload_span = tae_span.subspan(preamble_size, tae_size - preamble_size);

    int tae_offset = 0;

    // Copy the banks of the sub events and update the body of the TAEHeader bank
    for (int i = 0; i <= 2 * static_cast<int>(tae_event.half_window); ++i) {
      unsigned const event_number = tae_event.central - tae_event.half_window + i;
      unsigned const size_index = offset + i;
      // Add banks of this TAE sub event
      auto const sub_size = static_cast<int>(add_banks(
        store,
        slice_index,
        start_event,
        event_number,
        sizes.input[size_index],
        payload_span.subspan(tae_offset, sizes.input[size_index] + sizes.hlt[size_index])));

      // Fill the next triplet in the header payload
      for (int v : {i - static_cast<int>(tae_event.half_window), tae_offset, sub_size}) {
        *tae_header_payload++ = v;
      }

      // next sub event
      tae_offset += sub_size;
    }

    add_checksum(header, tae_span);

    // Next TAE event
    tae_output_offset += tae_size;
  }

  auto output_success = write_buffer(thread_id);

  return {output_success, tae_events.size()};
}

OutputSizes& OutputHandler::event_sizes(
  size_t const thread_id,
  size_t const slice_index,
  Allen::Store::PersistentStore const& store,
  std::vector<unsigned> const& selected_events,
  unsigned const start_event)
{
  auto& sizes = m_sizes[thread_id];
  sizes.fill_zero();
  m_input_provider->event_sizes(slice_index, selected_events, sizes.input);

  HLT1Outputs outputs {store};

  // size of the DecReport RawBank
  const unsigned dec_report_size = (m_nlines + 3) * sizeof(uint32_t);

  // Add the HLT bank sizes to event sizes
  for (size_t i = 0; i < selected_events.size(); ++i) {
    auto const event_number = selected_events[i] - start_event;
    // size of the SelReport RawBank
    // need the index into the batch here
    const unsigned sel_report_size =
      outputs.sel_reports_offsets.empty() ?
        0 :
        (outputs.sel_reports_offsets[event_number + 1] - outputs.sel_reports_offsets[event_number]) * sizeof(uint32_t);
    unsigned lumi_summary_size = 0;
    if (!outputs.lumi_summary_offsets.empty()) {
      lumi_summary_size =
        (outputs.lumi_summary_offsets[event_number + 1] - outputs.lumi_summary_offsets[event_number]) *
        sizeof(uint32_t);
    }

    for (auto hlt_bank_size : {dec_report_size, routing_bits_size, sel_report_size, lumi_summary_size}) {
      if (hlt_bank_size > 0) {
        sizes.hlt[i] += bank_header_size + hlt_bank_size;
      }
    }
  }

  return sizes;
}

LHCb::MDFHeader* OutputHandler::add_mdf_header(
  gsl::span<char> event_span,
  unsigned const run_number,
  gsl::span<unsigned const> routing_bits)
{

  auto const header_size = LHCb::MDFHeader::sizeOf(Allen::mdf_header_version);

  // Add the header
  auto* header = reinterpret_cast<LHCb::MDFHeader*>(event_span.data());
  // Set header version first so the subsequent call to setSize can
  // use it
  header->setHeaderVersion(Allen::mdf_header_version);
  // MDFHeader::setSize adds the header size internally, so pass
  // only the payload size here
  header->setSize(event_span.size() - header_size);

  // No compression here, handled at write time
  header->setCompression(0);
  header->setSubheaderLength(header_size - sizeof(LHCb::MDFHeader));
  header->setDataType(LHCb::MDFHeader::BODY_TYPE_BANKS);
  header->setSpare(0);

  // Put the routing bits into the trigger mask
  std::memcpy(&m_trigger_mask[0], routing_bits.data(), routing_bits.size_bytes());
  header->subHeader().H1->setTriggerMask(m_trigger_mask.data());
  // Set run number
  // FIXME: get orbit and bunch number from ODIN
  // The batch is offset by start_event with respect to the slice, so we add start_event
  header->subHeader().H1->setRunNumber(run_number);

  return header;
}

void OutputHandler::add_checksum(LHCb::MDFHeader* header, gsl::span<char> event_span)
{
  if (m_checksum) {
    auto const skip = 4 * sizeof(int);
    auto c = LHCb::hash32Checksum(event_span.data() + skip, event_span.size() - skip);
    header->setChecksum(c);
  }
  else {
    header->setChecksum(0);
  }
}

// WORKING: Fix this function
size_t OutputHandler::add_banks(
  Allen::Store::PersistentStore const& store,
  unsigned const slice_index,
  unsigned const start_event,
  unsigned const event_number,
  unsigned const input_size,
  gsl::span<char> event_span)
{

  HLT1Outputs outputs {store};

  // size of the DecReport RawBank
  const unsigned dec_report_size = (m_nlines + 3) * sizeof(uint32_t);

  // The batch is offset by start_event with respect to the slice, so we add start_event
  m_input_provider->copy_banks(
    slice_index, event_number + start_event, {event_span.data(), static_cast<events_size>(input_size)});

  // Starting point of HLT banks
  char* output = event_span.data() + input_size;

  // size of the SelReport RawBank
  // need the index into the batch here
  const unsigned sel_report_offset =
    outputs.sel_reports_offsets.empty() ? 0 : outputs.sel_reports_offsets[event_number];
  const unsigned sel_report_size =
    outputs.sel_reports_offsets.empty() ?
      0 :
      (outputs.sel_reports_offsets[event_number + 1] - outputs.sel_reports_offsets[event_number]) * sizeof(uint32_t);

  // size of the lumi summary RawBank
  // need the index into the batch here
  const unsigned lumi_summary_offset =
    outputs.lumi_summary_offsets.empty() ? 0 : outputs.lumi_summary_offsets[event_number];
  const unsigned lumi_summary_size =
    outputs.lumi_summary_offsets.empty() ?
      0 :
      (outputs.lumi_summary_offsets[event_number + 1] - lumi_summary_offset) * sizeof(uint32_t);

  using output_bank = std::tuple<LHCb::RawBank::BankType, unsigned, unsigned, gsl::span<char const>>;
  auto hlt_banks = std::make_tuple(
    // HltDecReports
    output_bank {LHCb::RawBank::HltDecReports,
                 3u,
                 Hlt1::Constants::sourceID,
                 {reinterpret_cast<char const*>(outputs.dec_reports.data()) + dec_report_size * event_number,
                  static_cast<events_size>(dec_report_size)}},
    // HltRoutingBits
    output_bank {LHCb::RawBank::HltRoutingBits,
                 0u,
                 Hlt1::Constants::sourceID,
                 {reinterpret_cast<char const*>(outputs.routing_bits.data()) + routing_bits_size * event_number,
                  static_cast<events_size>(routing_bits_size)}},
    // HltSelReports
    output_bank {LHCb::RawBank::HltSelReports,
                 11u, // TODO: change to 12u, update to run3 source ID...
                 Hlt1::Constants::sourceID_sel_reports,
                 {reinterpret_cast<char const*>(outputs.sel_reports.data()) + sel_report_offset * sizeof(uint32_t),
                  static_cast<events_size>(sel_report_size)}},
    // HltLumiSummary
    output_bank {LHCb::RawBank::HltLumiSummary,
                 2u,
                 Hlt1::Constants::sourceID,
                 {reinterpret_cast<char const*>(outputs.lumi_summaries.data()) + lumi_summary_offset * sizeof(uint32_t),
                  static_cast<events_size>(lumi_summary_size)}});

  // Lambda to add an HLT output bank to the output event
  auto add_hlt_bank = [](
                        LHCb::RawBank::BankType bank_type,
                        unsigned version,
                        unsigned source_id,
                        gsl::span<char const> data,
                        char* output) -> size_t {
    // add the dec report
    return data.empty() ? 0u : Allen::add_raw_bank(bank_type, version, source_id, data, output);
  };

  for_each(hlt_banks, [&output, &add_hlt_bank](auto b) {
    auto t = std::tuple_cat(b, std::tuple {output});
    output += std::apply(add_hlt_bank, t);
  });

  return static_cast<size_t>(output - event_span.data());
}
