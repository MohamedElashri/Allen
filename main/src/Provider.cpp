/*****************************************************************************\
 * (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <string>

#include <MDFProvider.h>
#include <Provider.h>
#include <BankTypes.h>
#include <ProgramOptions.h>
#include <InputReader.h>
#include <FileWriter.h>
#include <ZMQOutputSender.h>

#ifdef USE_BOOST_FILESYSTEM
#include <boost/filesystem.hpp>
#else
#include <filesystem>
#endif

namespace {
#ifdef USE_BOOST_FILESYSTEM
  namespace fs = boost::filesystem;
#else
  namespace fs = std::filesystem;
#endif
} // namespace

std::tuple<std::string, bool> Allen::sequence_conf(std::map<std::string, std::string> const& options)
{
  std::string json_configuration_file = "Sequence.json";
  // Sequence to run
  std::string sequence = "hlt1_pp_default";

  bool run_from_json = false;

  for (auto const& entry : options) {
    auto [flag, arg] = entry;
    if (flag_in(flag, {"sequence"})) {
      sequence = arg;
    }
    else if (flag_in(flag, {"run-from-json"})) {
      run_from_json = atoi(arg.c_str());
    }
  }

  // Determine configuration
  if (run_from_json) {
    if (fs::exists(sequence)) {
      json_configuration_file = sequence;
    }
    else {
      json_configuration_file = sequence + ".json";
    }
  }
  else {
    int error =
      system(("PYTHONPATH=code_generation/sequences:$PYTHONPATH python3 ../configuration/sequences/" + sequence + ".py")
               .c_str());
    if (error) {
      throw std::runtime_error("sequence generation failed");
    }
    info_cout << "\n";
  }

  return {json_configuration_file, run_from_json};
}

Allen::IOConf Allen::io_configuration(
  unsigned number_of_slices,
  unsigned number_of_repetitions,
  unsigned number_of_threads,
  bool quiet)
{
  // Determine wether to run with async I/O.
  Allen::IOConf io_conf {true, number_of_slices, number_of_repetitions, number_of_repetitions};
  if ((number_of_slices == 0 || number_of_slices == 1) && number_of_repetitions > 1) {
    // NOTE: Special case to be able to compare throughput with and
    // without async I/O; if repetitions are requested and the number
    // of slices is default (0) or 1, never free the initially filled
    // slice.
    io_conf.async_io = false;
    io_conf.number_of_slices = 1;
    io_conf.n_io_reps = 1;
    if (!quiet) {
      debug_cout << "Disabling async I/O to measure throughput without it.\n";
    }
  }
  else if (number_of_slices <= number_of_threads) {
    if (!quiet) {
      warning_cout << "Setting number of slices to " << number_of_threads + 1 << "\n";
    }
    io_conf.number_of_slices = number_of_threads + 1;
    io_conf.number_of_repetitions = 1;
  }
  else {
    if (!quiet) {
      info_cout << "Using " << number_of_slices << " input slices."
                << "\n";
    }
    io_conf.number_of_repetitions = 1;
  }
  return io_conf;
}

std::shared_ptr<IInputProvider> Allen::make_provider(std::map<std::string, std::string> const& options)
{

  unsigned number_of_slices = 0;
  unsigned events_per_slice = 0;
  std::optional<size_t> n_events;

  // Input file options
  std::string mdf_input = "../input/minbias/mdf/MiniBrunel_2018_MinBias_FTv4_DIGI.mdf";
  bool disable_run_changes = 0;

  // MPI options
  long number_of_events_requested = 0;

  unsigned n_repetitions = 1;
  unsigned number_of_threads = 1;

  std::string flag, arg;

  // Use flags to populate variables in the program
  for (auto const& entry : options) {
    std::tie(flag, arg) = entry;
    if (flag_in(flag, {"mdf"})) {
      mdf_input = arg;
    }
    else if (flag_in(flag, {"n", "number-of-events"})) {
      number_of_events_requested = atol(arg.c_str());
    }
    else if (flag_in(flag, {"s", "number-of-slices"})) {
      number_of_slices = atoi(arg.c_str());
    }
    else if (flag_in(flag, {"t", "threads"})) {
      number_of_threads = atoi(arg.c_str());
      if (number_of_threads > max_stream_threads) {
        error_cout << "Error: more than maximum number of threads (" << max_stream_threads << ") requested\n";
        return {};
      }
    }
    else if (flag_in(flag, {"r", "repetitions"})) {
      n_repetitions = atoi(arg.c_str());
      if (n_repetitions == 0) {
        error_cout << "Error: number of repetitions must be at least 1\n";
        return {};
      }
    }
    else if (flag_in(flag, {"events-per-slice"})) {
      events_per_slice = atoi(arg.c_str());
    }
    else if (flag_in(flag, {"disable-run-changes"})) {
      disable_run_changes = atoi(arg.c_str());
    }
  }

  // Set a sane default for the number of events per input slice
  if (number_of_events_requested != 0 && events_per_slice > number_of_events_requested) {
    events_per_slice = number_of_events_requested;
  }

  if (number_of_events_requested != 0) {
    n_events = number_of_events_requested;
  }

  auto const [json_file, run_from_json] = Allen::sequence_conf(options);
  auto io_conf = io_configuration(number_of_slices, n_repetitions, number_of_threads, true);

  // Bank types
  std::unordered_set<BankTypes> bank_types;
  ConfigurationReader configuration_reader {json_file};
  auto const& configuration = configuration_reader.params();
  for (auto const& [key, props] : configuration) {
    auto it = props.find("bank_type");
    if (it != props.end()) {
      auto type = it->second;
      auto const bt = bank_type(type);
      if (bt == BankTypes::Unknown) {
        error_cout << "Unknown bank type " << type << "requested.\n";
      }
      else {
        bank_types.emplace(bt);
      }
    }
  }

  if (!mdf_input.empty()) {
    MDFProviderConfig config {false,                     // verify MDF checksums
                              10,                        // number of read buffers
                              4,                         // number of transpose threads
                              events_per_slice * 10 + 1, // maximum number event of offsets in read buffer
                              events_per_slice,          // number of events per read buffer
                              io_conf.n_io_reps,         // number of loops over the input files
                              !disable_run_changes};     // Whether to split slices by run number
    return std::make_shared<MDFProvider>(
      io_conf.number_of_slices, events_per_slice, n_events, split_string(mdf_input, ","), bank_types, config);
  }
  return {};
}

std::unique_ptr<OutputHandler> Allen::output_handler(
  IInputProvider* input_provider,
  IZeroMQSvc* zmq_svc,
  std::map<std::string, std::string> const& options)
{
  std::string output_file;
  auto const [json_file, run_from_json] = Allen::sequence_conf(options);

  for (auto const& entry : options) {
    auto const [flag, arg] = entry;
    if (flag_in(flag, {"output-file"})) {
      output_file = arg;
    }
  }

  // Load constant parameters from JSON
  size_t n_lines = 0;
  ConfigurationReader configuration_reader {json_file};
  auto const& configuration = configuration_reader.params();
  auto conf_it = configuration.find("gather_selections");
  if (conf_it != configuration.end()) {
    auto prop_it = conf_it->second.find("names_of_active_lines");
    if (prop_it != conf_it->second.end()) {
      auto line_names = split_string(prop_it->second, ",");
      n_lines = line_names.size();
    }
  }

  std::unique_ptr<OutputHandler> output_handler;
  if (!output_file.empty()) {
    try {
      if (output_file.substr(0, 6) == "tcp://") {
        output_handler = std::make_unique<ZMQOutputSender>(input_provider, output_file, n_lines, zmq_svc);
      }
      else {
        output_handler = std::make_unique<FileWriter>(input_provider, output_file, n_lines);
      }
    } catch (std::runtime_error const& e) {
      error_cout << e.what() << "\n";
      return output_handler;
    }
  }
  return output_handler;
}
