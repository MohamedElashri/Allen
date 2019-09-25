#include <regex>
#include "InputTools.h"
#include "Common.h"

namespace {

  // Factory for filename checking: a regex and a predicate on the its matches
  using factory = std::tuple<std::regex, std::function<bool(const std::smatch&)>>;

  // Check binary files: they should match the regex and have n non-zero sub-matches
  const std::regex bin_format {"(\\d+)(?:_(\\d+))?\\.bin"};
  auto check_bin = [](size_t n) -> factory {
    return {bin_format, [n](const std::smatch& matches) {
              return std::accumulate(begin(matches) + 1, end(matches), 0ul, [](const auto& v, const auto& m) {
                       return v + (m.length() != 0);
                     }) == n;
            }};
  };

  // Check mdf files: they should match the regex and have not-empty filename
  auto check_ext = [](std::string ext) -> factory {
    const std::regex format {std::string{"(.+)\\."} + ext};
    return {format,
            [](const std::smatch& matches) { return matches.size() == 2 && matches.length(1) > 0; }};
  };

  // Check mep files: they should match the regex and have not-empty filename
  const std::regex mdf_format {"(.+)\\.mep"};
  auto check_mep = []() -> factory {
    return {mdf_format,
            [](const std::smatch& matches) { return matches.size() == 2 && matches.length(1) > 0; }};
  };

  // Check geometry files: they should match the regex.
  const std::regex geom_format {".*geometry.*"};
  auto check_geom = []() -> factory {
    return {geom_format, [](const std::smatch& matches) { return matches.size() == 1; }};
  };

  // Check all filenames using the regex and its match predicate
  // returned by calling the factory function
  auto check_names = [](const auto& names, const factory& fact) {
    // Check if all all names have the right format and the same format
    auto expr = std::get<0>(fact);
    const auto& pred = std::get<1>(fact);
    return std::all_of(begin(names), end(names), [&expr, &pred](const auto& t) {
      std::smatch matches;
      auto s = std::regex_match(t, matches, expr);
      // Check the predicate we've been given
      return s && pred(matches);
    });
  };

  // Sort in natural order by converting the filename to a pair of (int, long long)
  auto natural_order = [](const std::string& lhs, const std::string& rhs) -> bool {
    return std::less<EventID> {}(name_to_number(lhs), name_to_number(rhs));
  };

} // namespace

/**
 * @brief      Convert "N.bin" to (0, N) and "N_M.bin" to (N, M)
 *
 * @param      name
 *
 * @return     std::pair<int, unsigned long>
 */
EventID name_to_number(const std::string& arg)
{
  std::smatch m;
  if (!std::regex_match(arg, m, bin_format)) {
    return {0, 0};
  }
  else if (m.length(2) == 0) {
    return {0, std::stol(std::string {m[1].first, m[1].second})};
  }
  else {
    return {std::stoi(std::string {m[1].first, m[1].second}), std::stol(std::string {m[2].first, m[2].second})};
  }
}

/**
 * @brief Test to check existence of filename.
 */
bool exists_test(const std::string& name)
{
  std::ifstream f(name.c_str());
  return f.good();
}

/**
 * @brief Read files into vectors.
 */
void readFileIntoVector(const std::string& filename, std::vector<char>& events)
{
  std::ifstream infile(filename.c_str(), std::ifstream::binary);
  infile.seekg(0, std::ios::end);
  auto end = infile.tellg();
  infile.seekg(0, std::ios::beg);
  auto dataSize = end - infile.tellg();

  if (dataSize == 0) {
    warning_cout << "Empty file: " << filename << std::endl;
  }

  events.resize(dataSize);
  infile.read((char*) &(events[0]), dataSize);
  infile.close();
}

/**
 * @brief Appends a file to a vector of char.
 *        It can also be used to read a file to a vector,
 *        returning the event_size.
 */
void appendFileToVector(const std::string& filename, std::vector<char>& events, std::vector<unsigned int>& event_sizes)
{
  std::ifstream infile(filename.c_str(), std::ifstream::binary);
  infile.seekg(0, std::ios::end);
  auto end = infile.tellg();
  infile.seekg(0, std::ios::beg);
  auto dataSize = end - infile.tellg();

  if (dataSize == 0) {
    warning_cout << "Empty file: " << filename << std::endl;
  }

  // read content of infile with a vector
  const size_t previous_size = events.size();
  events.resize(events.size() + dataSize);
  infile.read(events.data() + previous_size, dataSize);
  event_sizes.push_back(dataSize);
  infile.close();
}

std::vector<std::string> list_folder(const std::string& foldername, const std::string& extension)
{
  std::vector<std::string> folderContents;
  DIR* dir;
  struct dirent* ent;
  std::string suffix = std::string {"."} + extension;
  // Find out folder contents
  if ((dir = opendir(foldername.c_str())) != NULL) {
    /* print all the files and directories within directory */
    while ((ent = readdir(dir)) != NULL) {
      std::string filename = ent->d_name;
      if (filename != "." && filename != "..") {
        folderContents.emplace_back(filename);
      }
    }
    closedir(dir);
    if (folderContents.size() == 0) {
      error_cout << "No " << extension << " files found in folder " << foldername << std::endl;
      exit(-1);
    }
    else if (
      !check_names(folderContents, check_geom()) && !check_names(folderContents, check_bin(1)) &&
      !check_names(folderContents, check_bin(2)) && !check_names(folderContents, check_ext(extension))) {
      error_cout << "Not all files in the folder have the correct and the same filename format." << std::endl;
      if (extension == ".bin") {
        error_cout << "All files should be named N.bin or all files should be named N_M.bin" << std::endl;
      }
      else {
        error_cout << "All files should end with ." << extension << std::endl;
      }
      exit(-1);
    }
    else {
      verbose_cout << "Found " << folderContents.size() << " binary files" << std::endl;
    }
  }
  else {
    error_cout << "Folder " << foldername << " could not be opened" << std::endl;
    exit(-1);
  }

  // Sort folder contents (file names)
  std::sort(folderContents.begin(), folderContents.end(), natural_order);

  return folderContents;
}

/**
 * @brief Processes the number of events requested. If 0,
 *        returns the size of the passed folder contents.
 */
uint get_number_of_events_requested(uint number_of_events_requested, const std::string& foldername)
{
  if (number_of_events_requested > 0) {
    return number_of_events_requested;
  }
  else {
    std::vector<std::string> folderContents = list_folder(foldername);
    return folderContents.size();
  }
}

/**
 * @brief Reads a number of events from a folder name.
 */
void read_folder(
  const std::string& foldername,
  const EventIDs& requested_events,
  std::vector<bool> const& event_mask,
  std::vector<char>& events,
  std::vector<unsigned int>& event_offsets,
  bool quiet)
{
  std::unordered_map<EventID, std::string> tracks_files;

  std::regex file_expr {"(\\d+)_(\\d+).*\\.bin"};
  std::smatch result;
  for (auto const& file : list_folder(foldername)) {
    if (std::regex_match(file, result, file_expr)) {
      tracks_files.emplace(std::tuple {std::atoi(result[1].str().c_str()), std::atol(result[2].str().c_str())}, file);
    }
  }

  for (auto const event_id : requested_events) {
    auto missing = !tracks_files.count(event_id);
    if (missing) {
      error_cout << "Missing file for event " << std::get<0>(event_id) << " " << std::get<1>(event_id) << std::endl;
      return;
    }
  }

  auto n_files = std::accumulate(event_mask.begin(), event_mask.end(), 0);
  std::vector<std::string> files;
  files.reserve(n_files);
  for (size_t i = 0; i < events.size(); ++i) {
    if (event_mask[i]) {
      auto event_id = requested_events[i];
      files.emplace_back(tracks_files[event_id]);
    }
  }

  read_files(files.cbegin(), files.cend(), events, event_offsets);

  if (!quiet) {
    debug_cout << std::endl << (event_offsets.size() - 1) << " files read" << std::endl << std::endl;
  }
}

/**
 * @brief Reads a number of events from a folder name.
 */
EventIDs read_folder(
  const std::string& foldername,
  uint number_of_events_requested,
  std::vector<char>& events,
  std::vector<uint>& event_offsets,
  const uint start_event_offset)
{
  std::vector<std::string> folderContents = list_folder(foldername);

  debug_cout << "Requested " << number_of_events_requested << " files" << std::endl;

  EventIDs event_ids;
  event_ids.reserve(folderContents.size());

  std::regex file_expr {"(\\d+)_(\\d+).*\\.bin"};
  std::smatch result;

  std::for_each(
    folderContents.begin() + start_event_offset,
    folderContents.end(),
    [&event_ids, &result, &file_expr](const auto& file) {
      if (std::regex_match(file, result, file_expr)) {
        event_ids.emplace_back(std::tuple {std::atoi(result[1].str().c_str()), std::atol(result[2].str().c_str())});
      }
      else {
        throw StrException {"event file " + file + " does not match expected filename pattern."};
      }
    });

  read_files(folderContents.begin() + start_event_offset, folderContents.end(), events, event_offsets);

  debug_cout << std::endl << (event_offsets.size() - 1) << " files read" << std::endl << std::endl;
  return event_ids;
}

void read_files(
  std::vector<std::string>::const_iterator file,
  std::vector<std::string>::const_iterator file_end,
  std::vector<char>& events,
  std::vector<uint>& event_offsets)
{
  // Read all requested events
  int readFiles = 0;
  unsigned int accumulated_size = 0;
  std::vector<unsigned int> event_sizes;
  event_sizes.reserve(std::distance(file, file_end));
  for (; file != file_end; ++file) {
    // Read event #i in the list and add it to the inputs
    appendFileToVector(*file, events, event_sizes);

    event_offsets.push_back(accumulated_size);
    accumulated_size += event_sizes.back();

    readFiles++;
    if ((readFiles % 100) == 0) {
      info_cout << "." << std::flush;
    }
  }
  // Add last offset
  event_offsets.push_back(accumulated_size);
}

/**
 * @brief Reads the geometry from foldername.
 */
void read_geometry(const std::string& filename, std::vector<char>& geometry)
{
  if (!exists_test(filename)) {
    throw StrException("Geometry file could not be found: " + filename);
  }
  readFileIntoVector(filename, geometry);
}

void read_muon_field_of_interest(std::vector<float>& foi_params, const std::string& filename)
{
  if (!exists_test(filename)) {
    throw StrException("Muon field of interest : " + filename);
  }

  std::ifstream stream(filename, std::ios::binary);
  float f;
  while (stream.read(reinterpret_cast<char*>(&f), sizeof(float))) {
    foi_params.push_back(f);
  }
}
