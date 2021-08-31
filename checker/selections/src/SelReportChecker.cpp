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
#include "SelReportChecker.h"

std::string const SelReportChecker::SelRepTag::name = "SelReportChecker";

void SelReportChecker::accumulate(
  const std::vector<std::string>& names_of_lines,
  const unsigned* sel_reps,
  const unsigned* sel_rep_offsets,
  const unsigned number_of_events)
{
  std::lock_guard<std::mutex> guard(m_mutex);
  const auto number_of_lines = names_of_lines.size();
  if (!m_event_counters.size()) {
    m_line_names = names_of_lines;
    m_event_counters = std::vector<unsigned>(number_of_lines, 0);
    m_candidates_counters = std::vector<unsigned>(number_of_lines, 0);
    m_hits_counter = 0;
    m_stdinfo_counter = 0;
    m_dec_counter = 0;
    m_track_counter = 0;
    m_sv_counter = 0;
  }

  const unsigned dec_clid = 1;
  const unsigned track_clid = 10010;
  const unsigned sv_clid = 10030;
  for (unsigned event_number = 0; event_number < number_of_events; event_number++) {
    const unsigned sel_rep_offset = sel_rep_offsets[event_number];
    const unsigned sel_rep_size = sel_rep_offsets[event_number + 1] - sel_rep_offset;
    if (sel_rep_size == 0) continue;
    const unsigned* event_sel_rep = sel_reps + sel_rep_offset;
    SelReport selrep(event_sel_rep);

    // Need the substructure and objtyp banks to count anything, so check for those.
    if (!selrep.subBankExists(1)) continue;

    RBObjTyp rb_objtyp(selrep.subBankPointerFromID(1));

    // Increment total counters.
    unsigned n_dec = 0;
    for (unsigned i = 0; i < rb_objtyp.numberOfObjTyp(); i++) {
      unsigned clid = rb_objtyp.getCLID(i);
      unsigned nobj = rb_objtyp.getObjCount(i);
      if (clid == dec_clid) {
        m_dec_counter += nobj;
        n_dec = nobj;
      }
      else if (clid == track_clid) {
        m_track_counter += nobj;
      }
      else if (clid == sv_clid) {
        m_sv_counter += nobj;
      }
    }

    // Need the stdinfo bank to check selection ID.
    if (!selrep.subBankExists(4) || !selrep.subBankExists(2)) continue;
    RBStdInfo rb_stdinfo(selrep.subBankPointerFromID(4));
    RBSubstr rb_substr(selrep.subBankPointerFromID(2));

    // Traverse the bank substructure.
    unsigned n_substr = rb_substr.numberOfObj();
    rb_stdinfo.rewind();
    rb_substr.rewind();
    for (unsigned i = 0; i < n_substr; ++i) {
      std::pair<unsigned int, std::vector<unsigned short>> substr = rb_substr.next();
      std::vector<float> stdinfo = rb_stdinfo.next();
      m_stdinfo_counter += stdinfo.size();
      if (i < n_dec) {
        uint dec_id = stdinfo[0];
        m_candidates_counters[dec_id - 1] += substr.second.size();
        ++m_event_counters[dec_id - 1];
      }
      // Get the hits info.
      if (substr.first) {
        RBHits rb_hits(selrep.subBankPointerFromID(0));
        unsigned i_seq = substr.second[0];
        m_hits_counter += rb_hits.seqSize(i_seq);
      }
    }
  }
}

void SelReportChecker::report(const size_t) const
{
  size_t longest_string = 10;
  for (const auto& line_name : m_line_names) {
    if (line_name.length() > longest_string) {
      longest_string = line_name.length();
    }
  }

  for (unsigned i = 0; i < longest_string; i++) {
    printf(" ");
  }
  printf("  Events  Candidates\n");
  for (unsigned i_line = 0; i_line < m_line_names.size(); i_line++) {
    std::printf("%s:", m_line_names[i_line].c_str());
    for (unsigned i = 0; i < longest_string - m_line_names[i_line].length(); ++i) {
      std::printf(" ");
    }
    std::printf(" %6i      %6i\n", m_event_counters[i_line], m_candidates_counters[i_line]);
  }

  std::printf("\n");

  std::printf("Total decisions: %u\n", m_dec_counter);
  std::printf("Total tracks:    %u\n", m_track_counter);
  std::printf("Total SVs:       %u\n", m_sv_counter);
  std::printf("Total hits:      %u\n", m_hits_counter);
  std::printf("Total stdinfo:   %u\n", m_stdinfo_counter);
  std::printf("\n");
}
