#pragma once

#include <sys/stat.h>

#include <regex>
#include <InputProvider.h>
#include <InputTools.h>
#include <BankTypes.h>
#include <TransposeTypes.h>

namespace {
  using namespace Allen::Units;

  /**
   * @brief      Utility function to order files given an existing ordering
   */
  void order_files(std::vector<std::string>& files, EventIDs const& order, std::string const& folder)
  {
    std::map<std::tuple<int, long long>, std::string> file_ids;
    for (auto file : files) {
      file_ids.emplace(name_to_number(file), file);
    }
    files.clear();
    for (auto event_id : order) {
      auto file_it = file_ids.find(event_id);
      if (file_it != file_ids.end()) {
        files.emplace_back(std::move(file_it->second));
      }
      else {
        auto [run, event] = file_it->first;
        throw StrException {std::string {"file with event ID "} + std::to_string(run) + " " + std::to_string(event) +
                            " not found in " + folder};
      }
    }
  }
} // namespace

/**
 * @brief      Provide event from binary files that are already in the correct
 *             layout for Allen
 *
 * @details    Files are opened and read in a separate thread to conform to
 *             the interface
 *
 * @param      number of slices
 * @param      number of events to fill per slice
 * @param      optional: number of events to read
 * @param      folders where to find banks for different types
 * @param      loop on input files
 * @param      optional: order of event IDs in which to provide bank data
 *
 */
template<BankTypes... Banks>
class BinaryProvider final : public InputProvider<BinaryProvider<Banks...>> {
public:
  BinaryProvider(
    size_t n_slices,
    size_t events_per_slice,
    std::optional<size_t> n_events,
    std::vector<std::string> connections,
    size_t repetitions = 1,
    std::optional<std::string> file_list = {},
    std::optional<EventIDs> order = std::optional<EventIDs> {}) :
    InputProvider<BinaryProvider<Banks...>> {n_slices, events_per_slice, n_events},
    m_slice_free(n_slices, true), m_repetitions {repetitions}, m_event_ids(n_slices)
  {

    // Check that there is a folder for each bank type, find all the
    // files it contains and store their sizes
    struct stat stat_buf;
    for (auto bank_type : this->types()) {
      auto it = std::find_if(connections.begin(), connections.end(), [bank_type](auto const& folder) {
        auto bn = bank_name(bank_type);
        return folder.substr(folder.size() - bn.size(), std::string::npos) == bn;
      });
      if (it == connections.end()) {
        throw StrException {"Failed to find a folder for " + bank_name(bank_type) + " banks"};
      }
      else {
        auto ib = to_integral<BankTypes>(bank_type);
        // Find files and order them if requested
        std::vector<std::string> contents;
        if (file_list) {
          if (!file_list.value().empty()) {
            std::string line;
            std::ifstream list(*file_list);
            if (list.is_open()) {
              while (std::getline(list, line)) {
                contents.push_back(line);
              }
            }
            else {
              throw StrException {"Could not open list of files"};
            }
          }
          else {
            contents = list_folder(*it);
          }
        }
        if (order) {
          order_files(contents, *order, *it);
        }
        // Get all file sizes
        m_sizes[ib].reserve(contents.size());
        for (auto const& file : contents) {
          auto path = *it + "/" + file;
          if (::stat(path.c_str(), &stat_buf) != 0) {
            throw StrException {"Failed to stat " + file};
          }
          else {
            m_sizes[ib].emplace_back(stat_buf.st_size);
          }
        }
        m_files[ib] = std::tuple {*it, std::move(contents)};
      }
    }

    // Reinitialize to take the possible minimum into account
    events_per_slice = this->events_per_slice();

    // Get event IDs from file names; assume they are all the same in
    // different folders
    auto const& some_files = std::get<1>(m_files.front());
    m_all_events.reserve(some_files.size());
    std::regex file_expr {"(\\d+)_(\\d+).*\\.bin"};
    std::smatch result;
    for (auto const& file : some_files) {
      if (std::regex_match(file, result, file_expr)) {
        m_all_events.emplace_back(std::tuple {std::atoi(result[1].str().c_str()), std::atol(result[2].str().c_str())});
      }
    }
    m_to_read = this->n_events() ? std::min(*this->n_events(), some_files.size()) : some_files.size();

    auto size_fun = [events_per_slice](BankTypes bank_type) -> std::tuple<size_t, size_t> {
      auto it = BankSizes.find(bank_type);
      auto ib = to_integral<BankTypes>(bank_type);
      if (it == end(BankSizes)) {
        throw std::out_of_range {std::string {"Bank type "} + std::to_string(ib) + " has no known size"};
      }
      return {std::lround((10 * sizeof(uint32_t) + it->second) * events_per_slice * bank_size_fudge_factor * kB),
              events_per_slice};
    };
    m_slices = allocate_slices<Banks...>(n_slices, size_fun);

    // Reserve space for event IDs
    for (size_t n = 0; n < n_slices; ++n) {
      m_event_ids[n].reserve(events_per_slice);
    }

    // start prefetch thread
    m_prefetch_thread = std::make_unique<std::thread>([this] { prefetch(); });
  }

  /**
   * @brief      Destructor; ensure prefetch threads is cleaned up
   */
  virtual ~BinaryProvider()
  {
    m_done = true;
    m_slice_cond.notify_one();
    m_prefetch_cond.notify_one();

    if (m_prefetch_thread) m_prefetch_thread->join();
  }

  /**
   * @brief      Get event IDs for a given slice
   *
   * @param      slice index
   *
   * @return     event IDs in slice
   */
  EventIDs event_ids(size_t slice_index, std::optional<size_t> first = {}, std::optional<size_t> last = {}) const override
  {
    auto const& ids = m_event_ids[slice_index];
    return {ids.begin() + (first ? *first : 0), ids.begin() + (last ? *last : ids.size())};
  }

  /**
   * @brief      Get a slice that is ready for processing; thread-safe
   *
   * @param      optional timeout
   *
   * @return     (good slice, input done, timed out, slice index, number of events in slice)
   */
  std::tuple<bool, bool, bool, size_t, size_t, uint> get_slice(
    std::optional<unsigned int> timeout = std::optional<unsigned int> {}) override
  {
    bool timed_out = false;
    size_t slice_index = 0, n_filled = 0;
    std::unique_lock<std::mutex> lock {m_prefetch_mut};
    if (!m_read_error) {
      // If no slices are ready, wait until one is available
      if (m_prefetched.empty()) {
        if (timeout) {
          timed_out = !m_prefetch_cond.wait_for(lock, std::chrono::milliseconds {*timeout}, [this] {
            return !m_prefetched.empty() || m_read_error || m_done;
          });
        }
        else {
          m_prefetch_cond.wait(lock, [this] { return !m_prefetched.empty() || m_read_error || m_done; });
        }
      }
      if (!m_read_error && !m_prefetched.empty() && (!timeout || (timeout && !timed_out))) {
        slice_index = m_prefetched.front();
        m_prefetched.pop_front();
        n_filled = std::get<3>(m_slices.front()[slice_index]) - 1;
      }
    }

    return {!m_read_error, m_done, timed_out, slice_index, n_filled, 0u};
  }

  /**
   * @brief      Declare a slice free for reuse; thread-safe
   *
   * @param      slice index
   *
   * @return     void
   */
  void slice_free(size_t slice_index) override
  {
    // Check if a slice was acually in use before and if it was, only
    // notify the transpose threads that a free slice is available
    bool freed = false;
    {
      std::unique_lock<std::mutex> lock {m_slice_mut};
      if (!m_slice_free[slice_index]) {
        m_slice_free[slice_index] = true;
        freed = true;
      }
    }
    if (freed) {
      this->debug_output("Freed slice " + std::to_string(slice_index));
      m_slice_cond.notify_one();
    }
  }

  /**
   * @brief      Obtain banks from a slice
   *
   * @param      BankType
   * @param      slice index
   *
   * @return     Banks and their offsets
   */
  BanksAndOffsets banks(BankTypes bank_type, size_t slice_index) const override
  {
    auto ib = to_integral<BankTypes>(bank_type);
    auto const& [banks, data_size, offsets, offsets_size] = m_slices[ib][slice_index];
    span<char const> b {banks[0].data(), offsets[offsets_size - 1]};
    span<unsigned int const> o {offsets.data(), offsets_size};
    return BanksAndOffsets {{std::move(b)}, offsets[offsets_size - 1], std::move(o)};
  }

  void event_sizes(size_t const, gsl::span<unsigned int const> const, std::vector<size_t>&) const override {}

  void copy_banks(size_t const, unsigned int const, gsl::span<char>) const override {}

private:
  /**
   * @brief      Function to steer prefetching of events; run on separate
   *             thread
   *
   * @return     void
   */
  void prefetch()
  {

    bool prefetch_done = false;
    size_t n_reps = 0;
    size_t eps = this->events_per_slice();

    size_t n_files = std::get<1>(m_files.front()).size();

    // Loop until the flag is set to exit, or the number of requested
    // event is reached
    while (!m_done) {
      // Find a free slice
      auto it = m_slice_free.end();
      {
        std::unique_lock<std::mutex> lock {m_slice_mut};
        it = find(m_slice_free.begin(), m_slice_free.end(), true);

        // If no free slice is available, wait for one
        if (it == m_slice_free.end()) {
          this->debug_output("Waiting for free slice", 1);
          m_slice_cond.wait(lock, [this, &it] {
            it = std::find(m_slice_free.begin(), m_slice_free.end(), true);
            return it != m_slice_free.end() || m_done;
          });
          if (m_done) {
            break;
          }
        }
        *it = false;
      }
      size_t slice_index = distance(m_slice_free.begin(), it);
      this->debug_output("Got slice index " + std::to_string(slice_index), 1);

      // "Reset" the slice
      auto& event_ids = m_event_ids[slice_index];
      reset_slice<Banks...>(m_slices, slice_index, event_ids);

      size_t n_read = 0;

      // Read files into the slice and keep track of the offsets
      while (!m_done && !m_read_error && n_read < eps && m_current < m_to_read && m_current < n_files) {
        auto inputs = open_files(m_current);
        if (m_read_error) break;

        // Check if any of the slices would be full
        for (auto bank_type : {Banks...}) {
          auto ib = to_integral<BankTypes>(bank_type);
          const auto& [slice, data_size, offsets, offsets_size] = m_slices[ib][slice_index];
          if ((offsets[offsets_size - 1] + std::get<2>(inputs[ib])) > slice[0].size()) {
            this->debug_output(std::string {"Slice "} + std::to_string(slice_index) + " is full.");
            goto done;
          }
        }

        for (auto& [bank_type, input, data_size] : inputs) {
          auto ib = to_integral<BankTypes>(bank_type);
          auto& [slice, slice_size, offsets, offsets_size] = m_slices[ib][slice_index];
          read_file(input, data_size, slice[0].data(), offsets.data(), offsets_size - 1);
          ++offsets_size;
        }
        m_event_ids[slice_index].emplace_back(m_all_events[m_current]);

        ++m_current;
        ++n_read;
        if ((m_current == m_to_read || m_current == n_files) && (++n_reps < m_repetitions)) {
          this->debug_output(
            "Loop " + std::to_string(n_reps) + " of " + std::to_string(std::min(m_to_read, n_files)) + " events");
          m_current = 0;
        }
      }
    done:
      this->debug_output("Read " + std::to_string(n_read) + " events into " + std::to_string(slice_index));

      prefetch_done = (m_current == m_to_read);
      if (prefetch_done) {
        this->debug_output("Prefetch done after " + std::to_string(n_reps) + " repetitions.");
      }
      // Notify waiting calls to get_slice that there is a new slice
      if (!m_read_error) {
        {
          std::unique_lock<std::mutex> lock {m_prefetch_mut};
          m_prefetched.push_back(slice_index);
        }
        m_done = prefetch_done;
        this->debug_output("Notifying one");
      }
      m_prefetch_cond.notify_one();
    }
  }

  /**
   * @brief      Open one file per bank type and get its size
   *
   * @param      index of the files
   *
   * @return     array of (bank type, open ifstrea, file size)
   */
  std::array<std::tuple<BankTypes, std::ifstream, size_t>, sizeof...(Banks)> open_files(size_t n)
  {
    std::array<std::tuple<BankTypes, std::ifstream, size_t>, sizeof...(Banks)> result;
    for (auto bank_type : {Banks...}) {
      auto ib = to_integral<BankTypes>(bank_type);
      auto filename = std::get<0>(m_files[ib]) + "/" + std::get<1>(m_files[ib])[n];
      std::ifstream input(filename, std::ifstream::binary);
      if (!input.is_open() || !input.good()) {
        m_read_error = true;
        this->debug_output(std::string {"Failed to open "} + filename);
        break;
      }
      auto data_size = m_sizes[ib][n];

      if (data_size == 0) {
        m_read_error = true;
        break;
      }
      result[ib] = make_tuple(bank_type, std::move(input), data_size);
    }
    return result;
  }

  /**
   * @brief      Read one file into a buffer
   *
   * @param      open ifstream
   * @param      number of bytes to read
   * @param      pointer to memory to write to
   * @param      pointer to offsets memory to store offset
   * @param      offset index
   *
   * @return     return type
   */
  void read_file(std::ifstream& input, size_t data_size, char* events, unsigned int* offsets, size_t n)
  {
    // read content
    size_t const previous_size = offsets[n];
    input.read(events + previous_size, data_size);
    offsets[n + 1] = previous_size + data_size;
  }

  // Pinned memory slices, N per banks types,
  Slices m_slices;

  // data members for prefetch thread
  std::mutex m_prefetch_mut;
  std::condition_variable m_prefetch_cond;
  std::deque<size_t> m_prefetched;
  std::unique_ptr<std::thread> m_prefetch_thread;

  // data members for slice synchronisation
  std::mutex m_slice_mut;
  std::condition_variable m_slice_cond;

  // Atomics to flag errors and completion
  std::atomic<bool> m_done = false;
  std::atomic<bool> m_read_error = false;

  // Keep track of what slices are free
  std::vector<bool> m_slice_free;

  // Index of the event file currently being read
  size_t m_current = 0;
  size_t m_to_read = 0;

  // Number of times to loop on available input files
  size_t m_repetitions = 1;

  // Run and event numbers of all available events
  std::vector<std::tuple<unsigned int, unsigned long>> m_all_events;

  // Run and events numbers of events in each slice
  std::vector<std::vector<std::tuple<unsigned int, unsigned long>>> m_event_ids;

  // Sizes of all files
  std::array<std::vector<size_t>, sizeof...(Banks)> m_sizes;

  // Folder and file names per bank type
  std::array<std::tuple<std::string, std::vector<std::string>>, sizeof...(Banks)> m_files;
};
