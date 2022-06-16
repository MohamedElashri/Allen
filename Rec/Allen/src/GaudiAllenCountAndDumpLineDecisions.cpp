/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#include "GaudiAllenCountAndDumpLineDecisions.h"

// Allen
#include "SelectionsEventModel.cuh"

// LHCb
#include "Kernel/STLExtensions.h"

#include <algorithm>

DECLARE_COMPONENT(GaudiAllenCountAndDumpLineDecisions)

GaudiAllenCountAndDumpLineDecisions::GaudiAllenCountAndDumpLineDecisions(
  const std::string& name,
  ISvcLocator* pSvcLocator) :
  Consumer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"allen_number_of_active_lines", ""},
     KeyValue {"allen_names_of_active_lines", ""},
     KeyValue {"allen_selections", ""},
     KeyValue {"allen_selections_offsets", ""}})
{}

StatusCode GaudiAllenCountAndDumpLineDecisions::initialize()
{
  auto sc = Consumer::initialize();
  if (sc.isFailure()) return sc;
  if (msgLevel(MSG::DEBUG)) {
    debug() << "==> Initialize" << endmsg;
  }

  for (const auto& name : m_line_names) {
    m_hlt1_line_rates.emplace_back(this, "Selected by " + name);

    if (msgLevel(MSG::DEBUG)) {
      debug() << "Added counter for line name " << name << endmsg;
    }
  }

  return StatusCode::SUCCESS;
}

void GaudiAllenCountAndDumpLineDecisions::operator()(
  const std::vector<unsigned>& allen_number_of_active_lines,
  const std::vector<char>& allen_names_of_active_lines,
  const std::vector<char>& allen_selections,
  const std::vector<unsigned>& allen_selections_offsets) const
{
  assert(allen_number_of_active_lines[0] == m_hlt1_line_rates.size());

  if (m_check_names && !check_line_names(allen_names_of_active_lines)) {
    error() << "Mismatch between external (property) and internal (allen) line lists.  Misalignment of counters likely."
            << endmsg;
  }

  const unsigned i_event = 0;
  const unsigned number_of_events = 1;

  // Selections view
  const Selections::Selections_t<const char> selections {
    allen_selections.data(), allen_selections_offsets.data(), number_of_events};

  // Increment counters
  for (unsigned line_index = 0; line_index < allen_number_of_active_lines[0]; line_index++) {
    bool line_dec = false;
    auto decs = selections.get_span(line_index, i_event);
    for (unsigned idec = 0; idec < decs.size(); idec++) {
      line_dec |= decs[idec];
    }
    m_hlt1_line_rates[line_index] += int(line_dec);
  }

  return;
}

// Check that the line names in the property m_line_names matche the Allen
// internal list of line names.
bool GaudiAllenCountAndDumpLineDecisions::check_line_names(const std::vector<char>& allen_names) const
{
  if (msgLevel(MSG::DEBUG)) {
    debug() << "Checking line names" << endmsg;
  }

  bool match = true;

  // Internal list of names is a expected to be a comma-delimited list
  // stored as a vector of chars.
  auto first = allen_names.begin();
  for (unsigned i = 0; i < m_line_names.size(); i++) {
    // Parse the next internal line name
    std::string gs_name;
    while (first != allen_names.end() && *first != ',' && *first != '\0') {
      gs_name.push_back(*first);
      first++;
    }
    // Increment beyond comma for the next line name.
    if (first != allen_names.end()) first++;

    // Suffix 'Decision' is appended externally in configuration.
    gs_name += "Decision";
    if (gs_name != m_line_names[i]) {
      match = false;
      error() << "Mismatch with internal line name: (#, <property>, <internal>): (" << i << ", " << m_line_names[i]
              << ", " << gs_name << ")" << endmsg;
    }

    if (msgLevel(MSG::DEBUG)) {
      std::string comp = (m_line_names[i] == gs_name) ? " == " : " != ";
      debug() << "Line name check " << i << ": " << m_line_names[i] << comp << gs_name << endmsg;
    }
  }

  return match;
}
