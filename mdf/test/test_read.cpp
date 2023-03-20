/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <cstring>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <unordered_set>
#include <map>
#include <bitset>
#include <optional>

#include <boost/program_options.hpp>
#include <boost/format.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/algorithm/string.hpp>
#include <optional>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#include "Event/RawBank.h"
#include "read_mdf.hpp"
#include "sourceid.h"

using namespace std;
namespace po = boost::program_options;
namespace ba = boost::algorithm;

int main(int argc, char* argv[])
{

  string filename;
  string dump;
  size_t n_events = 0;
  size_t n_skip = 0;
  bool quiet = false;

  // Declare the supported options.
  po::options_description desc("Allowed options");
  desc.add_options()("help,h", "produce help message")("filename,f", po::value<string>(&filename), "filename pattern")(
    "n_events,n", po::value<size_t>(&n_events), "number of events")(
    "quiet,q", po::bool_switch(&quiet)->default_value(false), "Only dump ODIN contents")(
    "skip,s", po::value<size_t>(&n_skip)->default_value(0), "number of events to skip")(
    "dump", po::value<string>(&dump), "dump bank content (bank_type,bank_number");

  po::positional_options_description p;
  p.add("filename", 1);
  p.add("n_events", 1);

  po::variables_map vm;
  po::store(po::command_line_parser(argc, argv).options(desc).positional(p).run(), vm);
  po::notify(vm);

  if (vm.count("help")) {
    std::cout << desc << "\n";
    return 1;
  }

  LHCb::RawBank::BankType dump_type = LHCb::RawBank::BankType::LastType;
  std::optional<unsigned> dump_n;
  if (!dump.empty()) {
    vector<string> entries;
    ba::split(entries, dump, boost::is_any_of(","));
#if defined(STANDALONE)
    dump_type = static_cast<LHCb::RawBank::BankType>(boost::lexical_cast<int>(entries[0]));
#else
    using Gaudi::Parsers::parse;
    auto sc = parse(dump_type, entries[0]);
    if (sc.isFailure()) {
      cout << "Invalid bank type: " << entries[0] << "\n";
      return 1;
    }
    if (entries.size() == 2) {
      dump_n = boost::lexical_cast<unsigned>(entries[1]);
    }
#endif
  }

  // Some storage for reading the events into
  LHCb::MDFHeader header;
  vector<char> read_buffer(1024 * 1024, '\0');
  vector<char> decompression_buffer(1024 * 1024, '\0');

  bool eof = false, error = false;

  std::vector<std::tuple<int, gsl::span<const char>>> event_span;

  auto input = MDF::open(filename.c_str(), O_RDONLY);
  if (input.good) {
    if (!quiet) {
      cout << "Opened " << filename << "\n";
    }
  }
  else {
    return -1;
  }

  size_t i_event = 0;
  size_t skipped = 0;
  while (!eof && (n_events == 0 || i_event < (n_events + n_skip))) {
    ++i_event;

    std::tie(eof, error, event_span) =
      MDF::read_event(input, header, read_buffer, decompression_buffer, true, dump.empty() && !quiet);
    if (eof) {
      input.close();
      return 0;
    }
    else if (error) {
      return -1;
    }
    else if (skipped++ < n_skip) {
      continue;
    }

    unsigned header_size = header.size();

    bool is_tae = event_span.size() != 1;
    // Put the banks in the event-local buffers
    if (dump.empty() && !quiet && is_tae) {
      cout << "TAE event with " << event_span.size() << " sub-events; total payload size " << header_size << "\n";
    }

    for (auto [bx, bank_span] : event_span) {
      array<size_t, LHCb::RawBank::LastType + 1> bank_counts {0};

      std::stringstream bank_stream, odin_stream, rb_stream;

      unsigned bank_total_size = 0;
      char const* bank = bank_span.data();
      char const* end = bank_span.data() + bank_span.size();
      while (bank < end) {
        const auto* b = reinterpret_cast<const LHCb::RawBank*>(bank);
        if (b->magic() != LHCb::RawBank::MagicPattern) {
          cout << "magic pattern failed: " << std::hex << b->magic() << std::dec << endl;
          goto error;
        }

        auto const source_id = b->sourceID();
        std::string det = SourceId_sysstr(source_id);
        std::string fill(7 - det.size(), ' ');

        bool dump_bank = b->type() == dump_type && (!dump_n || (dump_n && bank_counts[b->type()] == *dump_n));

        if (b->type() < LHCb::RawBank::LastType) {
          ++bank_counts[b->type()];
          if (b->type() == LHCb::RawBank::ODIN && (!dump.empty() || quiet)) {
            auto odin = MDF::decode_odin(b->range<unsigned>(), b->version());
            odin_stream << "run " << odin.runNumber() << " event " << std::setw(15) << odin.eventNumber()
                        << " event_type " << std::setw(2) << odin.eventType() << " trigger_type " << std::setw(2)
                        << odin.triggerType() << " TAE: " << odin.isTAE() << " first " << odin.timeAlignmentEventFirst()
                        << " window " << std::setw(2) << odin.timeAlignmentEventIndex() << " central "
                        << odin.timeAlignmentEventCentral();
          }

          if (b->type() == LHCb::RawBank::HltRoutingBits && (!dump.empty() || quiet)) {
            std::bitset<64> routing_bits {*(b->begin<unsigned long>())};
            rb_stream << "RBs: [";
            bool first = true;
            for (size_t i = 0; i < routing_bits.size(); ++i) {
              if (routing_bits[i]) {
                if (first)
                  first = false;
                else
                  rb_stream << ",";
                rb_stream << std::setw(2) << i;
              }
            }
            rb_stream << "]";
          }

          if (!quiet && (dump.empty() || dump_bank)) {
            bank_stream << "bank: " << std::setw(17) << std::left << b->type() << std::right << " version "
                        << std::setw(2) << b->version() << " sourceID: " << std::setw(6) << b->sourceID()
                        << " top5: " << std::setw(2) << SourceId_sys(source_id) << fill << " (" << det << ") "
                        << std::setw(5) << SourceId_num(source_id) << " " << std::setw(5) << b->size() << "\n";
          }
        }
        else {
          ++bank_counts[LHCb::RawBank::LastType];
        }

        if (!dump.empty() && dump_bank) {
          MDF::dump_hex(bank + b->hdrSize(), b->totalSize() - b->hdrSize(), bank_stream);
        }

        // Move to next raw bank
        bank += b->totalSize();
        if (b->type() != LHCb::RawBank::DAQ) {
          bank_total_size += b->totalSize();
        }
      }

      if (dump.empty() && !quiet) {
        if (is_tae) {
          cout << "TAE sub-event with bx " << bx << "\n";
        }
        cout << "Event " << std::setw(7) << i_event - 1
             << "; payload size: " << (is_tae ? bank_span.size() : header_size)
             << "; bank total size: " << bank_total_size << "\n";
        cout << "Type | #Banks\n";
        for (size_t i = 0; i < bank_counts.size(); ++i) {
          if (bank_counts[i] != 0) {
            cout << std::setw(17) << std::left << static_cast<LHCb::RawBank::BankType>(i) << " (" << std::setw(3)
                 << std::right << i << ") | " << std::setw(6) << bank_counts[i] << "\n";
          }
        }
      }
      cout << odin_stream.str() << " " << rb_stream.str() << "\n" << bank_stream.str();
      if (!quiet) cout << "\n";
    }
  }
error:
  input.close();
  return -1;
}
