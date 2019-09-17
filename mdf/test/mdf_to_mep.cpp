#include <cstring>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <unordered_set>
#include <numeric>
#include <map>

#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <raw_bank.hpp>
#include <read_mdf.hpp>
#include <eb_header.hpp>
#include <Common.h>
#include <BankTypes.h>

using namespace std;

int main(int argc, char* argv[]) {

  string output_file{argv[1]};
  if (argc < 2) {
    cout << "usage: mdf_to_mep output_file input.mdf ...\n";
    return -1;
  }

  vector<string> input_files(argc - 2);
  for (int i = 0; i < argc - 2; ++i) {
    input_files[i] = argv[i + 2];
  }

  int32_t packing_factor = 1000;
  size_t n_meps = 0;
  vector<char> buffer(1024 * 1024, '\0');
  vector<char> decompression_buffer(1024 * 1024, '\0');
  size_t offset = 0;

  LHCb::MDFHeader mdf_header;
  bool error = false;
  bool eof = false;
  gsl::span<char> bank_span;

  bool sizes_known = false;
  bool count_success = false;
  std::array<unsigned int, NBankTypes> banks_count;

  size_t n_read = 0;
  uint64_t event_id = 0;
  LHCb::RawBank::BankType prev_type = LHCb::RawBank::L0Calo;

  constexpr size_t n_bank_types = to_integral<LHCb::RawBank::BankType>(LHCb::RawBank::LastType);
  std::vector<std::tuple<EB::Header, EB::BlockHeader, size_t, vector<char>>> mfps;

  // offsets to fragments of the detector types
  std::array<size_t, n_bank_types> fragment_offsets{0};

  // Header version 3
  auto header_size = LHCb::MDFHeader::sizeOf(3);
  std::vector<char> header_buffer(header_size, '\0');
  auto* header = reinterpret_cast<LHCb::MDFHeader*>(header_buffer.data());
  header->setHeaderVersion(3);
  header->setDataType(LHCb::MDFHeader::BODY_TYPE_MEP);

  std::vector<char> block_buffer;

  auto output = ::open(output_file.c_str(), O_CREAT | O_RDWR);
  auto write = [&output] (void const*  data, size_t s) {
    return ::write(output, data, s);
  };

  auto write_fragments = [&n_read, &write, &block_buffer, &mfps, header_size, packing_factor, header] {
    if (n_read % packing_factor == 0 && n_read != 0) {
      header->setSize(header_size
                      + sizeof(EB::Header) * packing_factor
                      + std::accumulate(mfps.begin(), mfps.end(), 0,
                                        [] (size_t s, const auto& entry) {
                                          auto& [eb_header, block_header, n_filled, data] = entry;
                                          return s + block_header.headerSize() + block_header.block_size;
                                        }));
      write(header, header_size);
      for (auto& [eb_header, block_header, n_filled, data] : mfps) {
        write(&eb_header, sizeof(eb_header));
        block_buffer.reserve(block_header.header_size());
        block_header.serialize(block_buffer);
        write(block_buffer.data(), block_header.header_size());
        write(data.data(), block_header.block_size);

        // Reset the fragments
        block_header.block_size = 0;
        n_filled = 0;
      }
    }
  };

  for (auto const& file : input_files) {
    auto input = ::open(file.c_str(), O_RDONLY);
    if (input != -1) {
      cerr << "Failed to open " << file << " " << strerror(errno) << "\n";
      error = true;
      break;
    }
    else {
      cout << "Opened " << file << "\n";
    }
    while (!eof) {
      std::tie(eof, error, bank_span) = MDF::read_event(input, mdf_header, buffer, decompression_buffer, false);
      if (eof || error) {
        return -1;
      } else {
        ++n_read;
      }

      if (!sizes_known) {
        // Count the number of banks of each type
        std::tie(count_success, banks_count) = fill_counts(bank_span);
        auto n_fragments = std::accumulate(banks_count.begin(), banks_count.end(), 0);
        size_t offset = 0, i = 0;
        for (auto count : banks_count) {
          fragment_offsets[i++] = offset;
          offset += count;
        }
        mfps.resize(n_fragments);
        for (auto& [_, block_header, fragments] : mfps) {
          header = BlockHeader{0ul, packing_factor};
          frags.reserve(packing_factor * average_event_size);
        }

      }

      // Put the banks in the event-local buffers
      char const* bank = bank_span.begin();
      char const* end = bank_span.end();
      while (bank < end) {
        const auto* b = reinterpret_cast<const LHCb::RawBank*>(bank);
        if (b->magic() != LHCb::RawBank::MagicPattern) {
          cout << "magic pattern failed: " << std::hex << b->magic() << std::dec << endl;
          return -1;
        }

        if (b->type() < LHCb::RawBank::LastType) {
          auto fragment_index = fragment_offsets[b->type()] + b->sourceID();
          auto& [eb_header, block_header, n_filled, data] = mfps[fragment_index];

          if (n_filled == 0) {
            eb_header.source_id = b->souceID();
            eb_header.version = b->version();
            block_header = BlockHeader(event_id, packing_factor);
          }

          block_header.block_size
          block_header.types[n_filled] = b->type();
          block_header.sizes[n_filled] = b->size();
          // safety measure, shouldn't be called
          if (block_header.block_size + b->size() > data.size()) {
            cout << "Warning: data size insufficient, resizing\n";
            data.resize(1.5 * data.size());
          }
          ::memcpy(&data[0] + block_header.block_size, b->data(), b->size());
          block_header.block_size += b->size();
          ++n_filled;
        }

        // Move to next raw bank
        bank += b->totalSize();
      } else {
        cout << "unknown bank type: " << b->type() << endl;
      }

      write_fragments();
    }

    input.close();
  }

  if(success) {
    write_fragments();
  }
  return success ? 0 : -1;

}
