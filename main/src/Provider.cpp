/*****************************************************************************\
 * (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <string>
#include <iostream>
#include <fstream>
#include <regex>

#include <MDFProvider.h>
#include <Provider.h>
#include <BankTypes.h>
#include <ProgramOptions.h>
#include <InputReader.h>
#include <FileWriter.h>
#include <ZMQOutputSender.h>
#include <Event/RawBank.h>
#include <FileSystem.h>
#include <InputReader.h>

#ifndef ALLEN_STANDALONE
#include <TCK.h>
#endif

std::tuple<bool, bool> Allen::velo_decoding_type(const ConfigurationReader& configuration_reader)
{
  bool veloSP = false;
  bool retina = false;

  const auto& configured_sequence = configuration_reader.configured_sequence();
  for (const auto& alg : configured_sequence.configured_algorithms) {
    if (alg.id == "decode_retinaclusters::decode_retinaclusters_t") {
      retina = true;
    }
    else if (alg.id == "velo_masked_clustering::velo_masked_clustering_t") {
      veloSP = true;
    }
  }

  return {veloSP, retina};
}

std::tuple<std::string, std::string> Allen::sequence_conf(std::map<std::string, std::string> const& options)
{
  static bool generated = false;
  std::string json_configuration_file = "Sequence.json";
  std::string configuration_source;
  // Sequence to run
  std::string sequence = "hlt1_pp_default";

  for (auto const& entry : options) {
    auto [flag, arg] = entry;
    if (flag_in(flag, {"sequence"})) {
      sequence = arg;
    }
  }

  auto [from_tck, repo, tck] = config_from_tck(sequence);

  if (sequence == "null") {
    return {sequence, configuration_source};
  }
  else if (from_tck) {
#ifndef ALLEN_STANDALONE
    auto [config, config_source, tck_info] = load_tck(repo, tck);
    info_cout << "TCK " << tck << " loaded " << tck_info.type << " sequence from git with label " << tck_info.label
              << "\n";
    return {std::move(config), std::move(config_source)};
#else
    throw std::runtime_error {"Loading configuration from TCK is not supported in standalone builds"};
#endif
  }
  else {
    // Determine configuration
    if (sequence.size() > 5 && sequence.substr(sequence.size() - 5, std::string::npos) == ".json") {
      json_configuration_file = sequence;
      configuration_source = sequence;
    }
    else if (!generated) {
#ifdef ALLEN_STANDALONE
      const std::string allen_configuration_options = "--no-register-keys";
      const std::string allen_python_dir =
        (getenv("ALLEN_BUILD_DIR") != nullptr ? getenv("ALLEN_BUILD_DIR") : CMAKE_ALLEN_BUILD_DIR) +
        std::string("/code_generation/sequences/");
#else
      const std::string allen_configuration_options = "";
      const std::string allen_python_dir = getenv("ALLEN_INSTALL_DIR") + std::string("/python/");
#endif
      std::string python_file = allen_python_dir + "/AllenSequences/" + sequence + ".py";
      int error = system(("PYTHONPATH=" + allen_python_dir + ":$PYTHONPATH python3 " + allen_python_dir +
                          "/AllenCore/gen_allen_json.py " + allen_configuration_options + " --seqpath " + python_file +
                          " > /dev/null")
                           .c_str());
      if (error) {
        throw std::runtime_error {"sequence generation failed"};
      }
      info_cout << "\n";
      generated = true;
      configuration_source = python_file;
    }

    std::string config;
    std::ifstream config_file {json_configuration_file};
    if (!config_file.is_open()) {
      throw std::runtime_error {"failed to open sequence configuration file " + json_configuration_file};
    }

    return {std::string {std::istreambuf_iterator<char> {config_file}, std::istreambuf_iterator<char> {}},
            configuration_source};
  }
}

std::tuple<bool, std::string, std::string> Allen::config_from_tck(std::string_view source)
{
  std::regex tck_option {"([^:]+):(0x[a-fA-F0-9]{8})"};
  std::match_results<std::string_view::const_iterator> tck_match;
  std::string repo, tck;

  auto from_tck = std::regex_match(source.begin(), source.end(), tck_match, tck_option);
  if (from_tck) {
    repo = tck_match.str(1);
    tck = tck_match.str(2);
  }
  return {from_tck, repo, tck};
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

std::unique_ptr<IInputProvider> Allen::make_provider(
  std::map<std::string, std::string> const& options,
  std::string_view configuration)
{

  unsigned number_of_slices = 0;
  unsigned events_per_slice = 0;
  std::optional<size_t> n_events;
  unsigned verbosity = 3;

  // Input file options
  std::string mdf_input = "../input/minbias/mdf/MiniBrunel_2018_MinBias_FTv4_DIGI_retinacluster_v1.mdf";
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
    else if (flag_in(flag, {"v", "verbosity"})) {
      verbosity = atoi(arg.c_str());
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

  logger::setVerbosity(verbosity);

  // Set a sane default for the number of events per input slice
  if (number_of_events_requested != 0 && events_per_slice > number_of_events_requested) {
    events_per_slice = number_of_events_requested;
  }

  if (number_of_events_requested != 0) {
    n_events = number_of_events_requested;
  }

#ifdef TARGET_DEVICE_CUDA
  // For CUDA targets, set the maximum number of connections environment variable
  // equal to the number of thread/streams, with a maximum of 32.
  const auto cuda_device_max_connections = number_of_threads < 32 ? number_of_threads : 32;
  setenv("CUDA_DEVICE_MAX_CONNECTIONS", std::to_string(cuda_device_max_connections).c_str(), 1);
#endif

  ConfigurationReader configuration_reader {configuration};

  auto io_conf = io_configuration(number_of_slices, n_repetitions, number_of_threads, true);

  auto data_bank_types = DataBankTypes;
  auto bank_types = configuration_reader.configured_bank_types();
  bank_types.merge(data_bank_types);

  // This is a hack to avoid copying both SP and Retina banks to the device.
  auto [veloSP, retina] = Allen::velo_decoding_type(configuration_reader);
  std::unordered_set<LHCb::RawBank::BankType> skip_banks {};
  if (!veloSP && retina) {
    skip_banks.insert(LHCb::RawBank::Velo);
    skip_banks.insert(LHCb::RawBank::VP);
  }
  else if (veloSP && !retina) {
    skip_banks.insert(LHCb::RawBank::VPRetinaCluster);
  }

  if (!mdf_input.empty()) {
    auto connections = split_string(mdf_input, ",");

    // If a single file that does not end in .mdf is provided, assume
    // it contains a list of filenames, one per line. Each file should
    // exist and end in .mdf
    if (connections.size() == 1) {
      fs::path p {connections[0]};
      if (fs::exists(p) && p.extension() != ".mdf") {
        std::ifstream file(p.string());
        std::string line;
        while (std::getline(file, line)) {
          connections.push_back(line);
        }
        file.close();
        if (std::all_of(connections.begin() + 1, connections.end(), [](fs::path file) {
              return fs::exists(file) && file.extension() == ".mdf";
            })) {
          connections.erase(connections.begin());
        }
        else {
          error_cout << "Not all files listed in " << connections[0] << " are MDF files\n";
          return {};
        }
      }
    }

    MDFProviderConfig config {false,                     // verify MDF checksums
                              2,                         // number of transpose threads
                              events_per_slice * 10 + 1, // maximum number event of offsets in read buffer
                              events_per_slice,          // number of events per read buffer
                              io_conf.n_io_reps,         // number of loops over the input files
                              !disable_run_changes,      // Whether to split slices by run number
                              skip_banks};
    return std::make_unique<MDFProvider>(
      io_conf.number_of_slices, events_per_slice, n_events, connections, bank_types, config);
  }
  return {};
}

std::unique_ptr<OutputHandler> Allen::output_handler(
  IInputProvider* input_provider,
  IZeroMQSvc* zmq_svc,
  std::map<std::string, std::string> const& options)
{
  std::string output_file;
  size_t output_batch_size = 10;

  for (auto const& entry : options) {
    auto const [flag, arg] = entry;
    if (flag_in(flag, {"output-file"})) {
      output_file = arg;
    }
    else if (flag_in(flag, {"output-batch-size"})) {
      output_batch_size = atol(arg.c_str());
    }
  }

  if (!output_file.empty() && output_batch_size == 0) {
    error_cout << "Output batch size must not be 0\n";
    return {};
  }

  std::unique_ptr<OutputHandler> output_handler;
  if (!output_file.empty()) {
    try {
      if (output_file.substr(0, 6) == "tcp://") {
        output_handler = std::make_unique<ZMQOutputSender>(input_provider, output_file, output_batch_size, zmq_svc);
      }
      else {
        output_handler = std::make_unique<FileWriter>(input_provider, output_file, output_batch_size);
      }
    } catch (std::runtime_error const& e) {
      error_cout << e.what() << "\n";
      return output_handler;
    }
  }
  return output_handler;
}
