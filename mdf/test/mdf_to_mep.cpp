#include <cstring>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <unordered_set>
#include <numeric>
#include <map>
#include <cassert>

#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <raw_bank.hpp>
#include <read_mdf.hpp>
#include <eb_header.hpp>
#include <Transpose.h>
#include <Common.h>
#include <BankTypes.h>

using namespace std;

namespace detail {

  template <typename T>
  std::ostream& write( std::ostream& os, const T& t ) {
    // if you would like to know why there is a check for trivially copyable,
    // please read the 'notes' section of https://en.cppreference.com/w/cpp/types/is_trivially_copyable
    if constexpr ( gsl::details::is_span<T>::value ) {
      return os.write( reinterpret_cast<const char*>( t.data() ), t.size_bytes() );
    } else if constexpr ( std::is_trivially_copyable_v<T> && !gsl::details::is_span<T>::value ) {
      return os.write( reinterpret_cast<const char*>( &t ), sizeof( T ) );
    } else {
      static_assert( std::is_trivially_copyable_v<typename T::value_type> );
      return write( os, as_bytes( gsl::make_span( t ) ) );
    }
  }

} // namespace detail

class FileWriter {
  std::ofstream m_f;

public:
  FileWriter( const std::string& name ) : m_f{name, std::ios::out | std::ios::binary} {}

  bool is_open() {
    return m_f.is_open();
  }

  template <typename... Args>
  FileWriter& write( Args&&... args ) {
    ( detail::write( m_f, std::forward<Args>( args ) ), ... );
    return *this;
  }
};

int main(int argc, char* argv[]) {

  if (argc < 4) {
    cout << "usage: mdf_to_mep output_file #MEPs packing_factor input.mdf ...\n";
    return -1;
  }

  string output_file{argv[1]};
  size_t n_meps = std::atol(argv[2]);
  uint16_t packing_factor = std::atoi(argv[3]);

  vector<string> input_files(argc - 4);
  for (int i = 0; i < argc - 4; ++i) {
    input_files[i] = argv[i + 4];
  }

  vector<char> buffer(1024 * 1024, '\0');
  vector<char> decompression_buffer(1024 * 1024, '\0');

  LHCb::MDFHeader mdf_header;
  bool error = false;
  bool eof = false;
  gsl::span<char> bank_span;

  bool sizes_known = false;
  bool count_success = false;
  std::array<unsigned int, LHCb::NBankTypes> banks_count;

  size_t n_read = 0;
  size_t n_written = 0;
  uint64_t event_id = 0;

  std::vector<std::tuple<EB::BlockHeader, size_t, vector<char>>> blocks;
  EB::Header mep_header;

  // offsets to fragments of the detector types
  std::array<size_t, LHCb::NBankTypes> block_offsets{0};

  // Header version 3
  auto hdr_size = LHCb::MDFHeader::sizeOf(3);
  std::vector<char> header_buffer(hdr_size, '\0');
  auto* header = reinterpret_cast<LHCb::MDFHeader*>(header_buffer.data());
  header->setHeaderVersion(3);
  header->setDataType(LHCb::MDFHeader::BODY_TYPE_MEP);
  header->setSubheaderLength(hdr_size - sizeof(LHCb::MDFHeader));

  FileWriter writer{output_file};
  if (!writer.is_open()) {
    cerr << "Failed to open output file: " << strerror(errno) << "\n";
    return -1;
  }

  auto write_fragments = [&writer, &blocks, &n_written, &mep_header, hdr_size, packing_factor, header] {
    header->setSize(mep_header.header_size(blocks.size())
                    + std::accumulate(blocks.begin(), blocks.end(), 0,
                                      [packing_factor] (size_t s, const auto& entry) {
                                        auto& [block_header, n_filled, data] = entry;
                                        return s + block_header.header_size(packing_factor)
                                          + block_header.block_size;
                                      }));
    writer.write(gsl::span{reinterpret_cast<char const*>(header), hdr_size});

    size_t block_offset = 0;
    for(size_t ib = 0; ib < blocks.size(); ++ib) {
      mep_header.offsets[ib] = block_offset;
      auto const& block = std::get<0>(blocks[ib]);
      block_offset += block.header_size(block.n_frag) + block.block_size;
    }
    mep_header.mep_size = block_offset;
    mep_header.packing_factor = packing_factor;

    writer.write(mep_header.n_blocks, mep_header.packing_factor, mep_header.reserved,
                 mep_header.mep_size,
                 mep_header.source_ids, mep_header.versions, mep_header.offsets);

    for (auto& [block_header, n_filled, data] : blocks) {
      assert(std::accumulate(block_header.sizes.begin(), block_header.sizes.end(), 0) == block_header.block_size);
      writer.write(block_header.event_id, block_header.n_frag, block_header.reserved, block_header.block_size,
                   block_header.types, block_header.sizes);
      writer.write(gsl::span{data.data(), block_header.block_size});

      // Reset the fragments
      block_header.block_size = 0;
      n_filled = 0;
    }
    ++n_written;
  };

  for (auto const& file : input_files) {
    auto input = MDF::open(file.c_str(), O_RDONLY);
    if (input.good) {
      cout << "Opened " << file << "\n";
    }
    else {
      cerr << "Failed to open " << file << " " << strerror(errno) << "\n";
      error = true;
      break;
    }
    while (!eof && n_written < n_meps) {
      std::tie(eof, error, bank_span) = MDF::read_event(input, mdf_header, buffer, decompression_buffer, false);
      if (eof) {
        eof = false;
        break;
      } else if (error) {
        cerr << "Failed to read event\n";
        return -1;
      } else {
        ++n_read;
      }

      if (!sizes_known) {
        // Count the number of banks of each type and the start of the
        // source ID range
        std::tie(count_success, banks_count) = fill_counts(bank_span);
        // Skip DAQ bank
        uint16_t n_blocks = std::accumulate(banks_count.begin(), banks_count.end(), 0)
          - banks_count[LHCb::RawBank::DAQ];
        size_t offset = 0, i = 0;
        for (i = 0; i < banks_count.size(); ++i) {
          if (i != to_integral(LHCb::RawBank::DAQ)) {
            block_offsets[i] = offset;
            offset += banks_count[i];
          }
        }
        blocks.resize(n_blocks);
        for (auto& block : blocks) {
          std::get<2>(block).resize(packing_factor * average_event_size * kB / n_blocks);
        }

        mep_header = EB::Header{packing_factor, n_blocks};
        sizes_known = true;
      }

      // Put the banks in the event-local buffers
      char const* bank = bank_span.begin();
      char const* end = bank_span.end();
      size_t source_offset = 0;
      auto prev_type = LHCb::RawBank::L0Calo;
      while (bank < end) {
        const auto* b = reinterpret_cast<const LHCb::RawBank*>(bank);
        if (b->magic() != LHCb::RawBank::MagicPattern) {
          cout << "magic pattern failed: " << std::hex << b->magic() << std::dec << endl;
          return -1;
        }

        // Skip the DAQ bank, it's created on read from the MDF header
        if (b->type() < LHCb::RawBank::LastType && b->type() != LHCb::RawBank::DAQ) {
          if (b->type() != prev_type) {
            source_offset = 0;
            prev_type = b->type();
          } else {
            ++source_offset;
          }
          auto block_index = block_offsets[b->type()] + source_offset;
          auto& [block_header, n_filled, data] = blocks[block_index];

          if (n_filled == 0) {
            mep_header.source_ids[block_index] = b->sourceID();
            mep_header.versions[block_index] = b->version();
            block_header = EB::BlockHeader{event_id, packing_factor};
          } else if (mep_header.source_ids[block_index] != b->sourceID()) {
            cout << "Error: banks not ordered in the same way: "
                 << mep_header.source_ids[block_index] << " " << b->sourceID() << "\n";
            return -1;
          }

          // NOTE: All banks are truncated to 32 bit values. This
          // doesn't seem to make a difference except for the UT,
          // where the size is larger than the number of words o.O
          auto n_words = b->size() / sizeof(uint32_t);
          auto word_size = n_words * sizeof(uint32_t);
          block_header.types[n_filled] = b->type();
          block_header.sizes[n_filled] = n_words * sizeof(uint32_t);

          // Resize on demand
          if (block_header.block_size + word_size > data.size()) {
            data.resize(1.5 * data.size());
          }

          // Copy bank data
          ::memcpy(&data[0] + block_header.block_size, b->data(), word_size);
          block_header.block_size += word_size;

          ++n_filled;
        } else if (b->type() != LHCb::RawBank::DAQ) {
          cout << "unknown bank type: " << b->type() << endl;
        }

        // Move to next raw bank
        bank += b->totalSize();
      }

      if (n_read % packing_factor == 0 && n_read != 0) {
        write_fragments();
        event_id += packing_factor;
      }
    }

    input.close();
    if (n_written >= n_meps) break;
  }

  if (!error) {
    cout << "Wrote " << n_written << " MEPs with " << (n_read % packing_factor) << " events left over.\n";
  }

  return error ? -1 : 0;

}
