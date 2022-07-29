/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "HostRoutingBitsWriter.h"
#include "ProgramOptions.h"
#include "HltDecReport.cuh"

INSTANTIATE_ALGORITHM(host_routingbits_writer::host_routingbits_writer_t)

void host_routingbits_writer::host_routingbits_writer_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<host_routingbits_t>(arguments, RoutingBitsDefinition::n_words * first<host_number_of_events_t>(arguments));
}

void host_routingbits_writer::host_routingbits_writer_t::init() const
{
  const auto name_to_id_map = m_name_to_id_map.get_value().get();
  const auto rb_map = m_routingbit_map.get_value().get();
  const auto nlines = name_to_id_map.size();

  // Find set of decisionIDs that match each routing bit
  for (auto const& [expr, bit] : rb_map) {
    std::regex rb_regex(expr);
    boost::dynamic_bitset<> rb_bitset(nlines);
    for (auto const& [name, id] : name_to_id_map) {
      if (std::regex_match(name, rb_regex)) {
        debug_cout << "Bit: " << bit << " expression: " << expr << " matched to line: " << name << " with ID " << id
                   << std::endl;
        rb_bitset[id] = 1;
      }
    }
    m_rb_ids[bit] = rb_bitset;
  }
}

void host_routingbits_writer::host_routingbits_writer_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  Allen::memset<host_routingbits_t>(arguments, 0, context);

  host_routingbits_impl(
    first<host_number_of_events_t>(arguments),
    first<host_number_of_active_lines_t>(arguments),
    data<host_names_of_active_lines_t>(arguments),
    data<host_dec_reports_t>(arguments),
    data<host_routingbits_t>(arguments),
    m_rb_ids);
  // Copy routing bit info to the host buffer
  host_buffers.host_routingbits.resize(size<host_routingbits_t>(arguments));
  Allen::copy(
    host_buffers.host_routingbits.get(), get<host_routingbits_t>(arguments), context, Allen::memcpyHostToHost);
}

void host_routingbits_writer::host_routingbits_impl(
  unsigned host_number_of_events,
  unsigned host_number_of_active_lines,
  char* host_names_of_active_lines,
  unsigned* host_dec_reports,
  unsigned* host_routing_bits,
  const std::unordered_map<uint32_t, boost::dynamic_bitset<>>& rb_ids)
{
  auto line_names = split_string(static_cast<char const*>(host_names_of_active_lines), ",");

  boost::dynamic_bitset<> fired(host_number_of_active_lines);
  for (unsigned event = 0; event < host_number_of_events; ++event) {

    fired.reset();

    unsigned* bits = host_routing_bits + RoutingBitsDefinition::n_words * event;

    unsigned const* dec_reports = host_dec_reports + (2 + host_number_of_active_lines) * event;
    for (unsigned line_index = 0; line_index < host_number_of_active_lines; ++line_index) {
      HltDecReport dec_report {dec_reports[2 + line_index]};
      if (dec_report.decision())
        fired.set(dec_report.decisionID() - 1); // offset of decisionIDs starts from 1 while dynamic_bitset starts from
                                                // 0
    }

    // set routing bit based on set of decisionIDs that match it
    for (auto const& [bit, line_ids] : rb_ids) {
      auto rb_fired = line_ids.intersects(fired);
      int word = bit / 32;
      if (rb_fired) {
        bits[word] |= (0x01UL << (bit - 32 * word));
      }
    }

    if (logger::verbosity() >= logger::debug) {
      debug_cout << " HostRoutingBits: Event n. " << event << ", routing bits: ";
      for (int i = 0; i < RoutingBitsDefinition::n_words; i++) {
        debug_cout << bits[i] << "  ";
      }
      debug_cout << std::endl;
    }
  }
}
