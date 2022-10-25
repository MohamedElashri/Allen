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
#include <Store.cuh>

std::tuple<bool, size_t> OutputHandler::output_selected_events(
  size_t const thread_id,
  size_t const slice_index,
  size_t const start_event,
  const Allen::Store::PersistentStore& store)
{
  // TODO: Use configuration framework to properly configure these tags
  const auto [selected_events_bool_valid, selected_events_bool] =
    store.try_at<bool>("global_decision__host_global_decision_t");
  const auto [dec_reports_valid, dec_reports] = store.try_at<unsigned>("dec_reporter__host_dec_reports_t");
  const auto [routing_bits_valid, routing_bits] = store.try_at<unsigned>("host_routingbits_writer__host_routingbits_t");
  const auto [sel_reports_valid, sel_reports] = store.try_at<unsigned>("make_selreps__host_sel_reports_t");
  const auto [sel_report_offsets_valid, sel_report_offsets] =
    store.try_at<unsigned>("make_selreps__host_selrep_offsets_t");
  const auto [lumi_summaries_valid, lumi_summaries] =
    store.try_at<unsigned>("make_lumi_summary__host_lumi_summaries_t");
  const auto [lumi_summary_offsets_valid, lumi_summary_offsets] =
    store.try_at<unsigned>("make_lumi_summary__host_lumi_summary_offsets_t");

  auto const header_size = LHCb::MDFHeader::sizeOf(Allen::mdf_header_version);
  // size of a RawBank header
  const int bank_header_size = 4 * sizeof(short);
  // size of the DecReport RawBank
  const unsigned dec_report_size = (m_nlines + 3) * sizeof(uint32_t);
  // size of the RoutingBits RawBank
  const unsigned routing_bits_size = RoutingBitsDefinition::n_words * sizeof(uint32_t);

  std::vector<unsigned> selected_events;
  selected_events.reserve(selected_events_bool.size());
  for (unsigned i = 0; i < selected_events_bool.size(); ++i) {
    if (selected_events_bool[i]) {
      // selected_events is passed to the InputProvider to get the
      // event sizes. The InputProvider doesn't know about slice
      // splitting, so we have to offset by start_event here.
      selected_events.push_back(i + start_event);
    }
  }

  auto const n_events = static_cast<size_t>(selected_events.size());
  if (n_events == 0) return {true, 0};

  // m_sizes will contain the total size of all banks in the event
  auto& event_sizes = m_sizes[thread_id];

  std::fill_n(event_sizes.begin(), event_sizes.size(), 0);
  m_input_provider->event_sizes(slice_index, selected_events, event_sizes);
  auto event_ids = m_input_provider->event_ids(slice_index);

  bool output_success = true;
  size_t n_output = 0;
  size_t n_batches = n_events / m_output_batch_size + (n_events % m_output_batch_size != 0);

  // Lambda to add an HLT output bank to the output event
  auto add_hlt_bank = [](
                        LHCb::RawBank::BankType bank_type,
                        unsigned version,
                        unsigned source_id,
                        gsl::span<char const> data,
                        char* output) -> size_t {
    // add the dec report
    if (data.empty()) {
      return 0u;
    }
    else {
      Allen::add_raw_bank(bank_type, version, source_id, data, output);
      return bank_header_size + data.size_bytes();
    }
  };

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

      // The event number is constructed to index into a batch. The 0th
      // event of a batch is start_event in a slice, so we subtract
      // start_event that was added to selected_events to have a direct
      // index into the batch again.
      auto const event_number = selected_events[i] - start_event;

      // size of the SelReport RawBank
      // need the index into the batch here
      const unsigned sel_report_size =
        sel_report_offsets.empty() ?
          0 :
          (sel_report_offsets[event_number + 1] - sel_report_offsets[event_number]) * sizeof(uint32_t);
      unsigned lumi_summary_size = 0;
      if (!lumi_summary_offsets.empty()) {
        lumi_summary_size =
          (lumi_summary_offsets[event_number + 1] - lumi_summary_offsets[event_number]) * sizeof(uint32_t);
      }

      // add DecReport and SelReport sizes to the total size (including RawBank headers)
      // event_sizes is indexed in the same way as selected_events
      size_t event_size =
        event_sizes[i] + header_size + bank_header_size + dec_report_size + bank_header_size + routing_bits_size;
      if (sel_report_size > 0) {
        event_size += bank_header_size + sel_report_size;
      }
      if (lumi_summary_size > 0) {
        event_size += bank_header_size + lumi_summary_size;
      }
      batch_buffer_size += event_size;
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

      // size of the SelReport RawBank
      // need the index into the batch here
      const unsigned sel_report_offset = sel_report_offsets.empty() ? 0 : sel_report_offsets[event_number];
      const unsigned sel_report_size =
        sel_report_offsets.empty() ? 0 : (sel_report_offsets[event_number + 1] - sel_report_offset) * sizeof(uint32_t);

      const unsigned lumi_summary_offset = lumi_summary_offsets.empty() ? 0 : lumi_summary_offsets[event_number];
      const unsigned lumi_summary_size =
        lumi_summary_offsets.empty() ?
          0 :
          (lumi_summary_offsets[event_number + 1] - lumi_summary_offset) * sizeof(uint32_t);

      // event_sizes is indexed in the same way as selected_events
      size_t event_size = event_sizes[i] + header_size;
      for (auto hlt_bank_size : {dec_report_size, routing_bits_size, sel_report_size, lumi_summary_size}) {
        if (hlt_bank_size > 0) {
          event_size += bank_header_size + hlt_bank_size;
        }
      }

      // The memory range in the output buffer for this event
      auto event_span = batch_span.subspan(output_event_offset, event_size);

      // Add the header
      auto* header = reinterpret_cast<LHCb::MDFHeader*>(event_span.data());
      // Set header version first so the subsequent call to setSize can
      // use it
      header->setHeaderVersion(Allen::mdf_header_version);
      // MDFHeader::setSize adds the header size internally, so pass
      // only the payload size here
      header->setSize(event_size - header_size);

      // No compression here, handled at write time
      header->setCompression(0);
      header->setSubheaderLength(header_size - sizeof(LHCb::MDFHeader));
      header->setDataType(LHCb::MDFHeader::BODY_TYPE_BANKS);
      header->setSpare(0);
      // Fixed triggermask for now
      std::memcpy(
        &m_trigger_mask[0], routing_bits.data() + RoutingBitsDefinition::n_words * event_number, routing_bits_size);
      header->subHeader().H1->setTriggerMask(m_trigger_mask.data());
      // Set run number
      // FIXME: get orbit and bunch number from ODIN
      // The batch is offset by start_event with respect to the slice, so we add start_event
      header->subHeader().H1->setRunNumber(
        static_cast<unsigned int>(std::get<0>(event_ids[event_number + start_event])));

      // The batch is offset by start_event with respect to the slice, so we add start_event
      m_input_provider->copy_banks(
        slice_index,
        event_number + start_event,
        {event_span.data() + header_size, static_cast<events_size>(event_sizes[i])});

      // Starting point of HLT banks
      char* output = event_span.data() + header_size + event_sizes[i];

      using output_bank = std::tuple<LHCb::RawBank::BankType, unsigned, unsigned, gsl::span<char const>>;
      auto hlt_banks = std::make_tuple(
        // HltDecReports
        output_bank {LHCb::RawBank::HltDecReports,
                     3u,
                     Hlt1::Constants::sourceID,
                     {reinterpret_cast<char const*>(dec_reports.data()) + dec_report_size * event_number,
                      static_cast<events_size>(dec_report_size)}},
        // HltRoutingBits
        output_bank {LHCb::RawBank::HltRoutingBits,
                     0u,
                     Hlt1::Constants::sourceID,
                     {reinterpret_cast<char const*>(routing_bits.data()) + routing_bits_size * event_number,
                      static_cast<events_size>(routing_bits_size)}},
        // HltSelReports
        output_bank {LHCb::RawBank::HltSelReports,
                     11u, // TODO: change to 12u, update to run3 source ID...
                     Hlt1::Constants::sourceID_sel_reports,
                     {reinterpret_cast<char const*>(sel_reports.data()) + sel_report_offset * sizeof(uint32_t),
                      static_cast<events_size>(sel_report_size)}},
        // HltLumiSummary
        output_bank {LHCb::RawBank::HltLumiSummary,
                     2u,
                     Hlt1::Constants::sourceID,
                     {reinterpret_cast<char const*>(lumi_summaries.data()) + lumi_summary_offset * sizeof(uint32_t),
                      static_cast<events_size>(lumi_summary_size)}});

      for_each(hlt_banks, [&output, &add_hlt_bank](auto b) {
        auto t = std::tuple_cat(b, std::tuple {output});
        output += std::apply(add_hlt_bank, t);
      });

      if (m_checksum) {
        auto const skip = 4 * sizeof(int);
        auto c = LHCb::hash32Checksum(event_span.data() + skip, event_span.size() - skip);
        header->setChecksum(c);
      }
      else {
        header->setChecksum(0);
      }

      output_event_offset += event_size;
    }

    auto output_success = write_buffer(thread_id);
    n_output += output_success ? batch_size : 0;
  }
  assert(n_events - n_output == 0);
  return {output_success, n_output};
}
