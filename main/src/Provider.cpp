/*****************************************************************************\
 * (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <string>

#include <MDFProvider.h>
#include <BinaryProvider.h>
#include <Provider.h>
#include <BankTypes.h>
#include <ProgramOptions.h>

Allen::IOConf Allen::io_configuration(unsigned number_of_slices, unsigned number_of_repetitions, unsigned number_of_threads)
{
  // Determine wether to run with async I/O.
  Allen::IOConf io_conf{true, number_of_slices, number_of_repetitions, number_of_repetitions};
  if ((number_of_slices == 0 || number_of_slices == 1) && number_of_repetitions > 1) {
    // NOTE: Special case to be able to compare throughput with and
    // without async I/O; if repetitions are requested and the number
    // of slices is default (0) or 1, never free the initially filled
    // slice.
    io_conf.async_io = false;
    io_conf.number_of_slices = 1;
    io_conf.n_io_reps = 1;
    debug_cout << "Disabling async I/O to measure throughput without it.\n";
  }
  else if (number_of_slices <= number_of_threads) {
    warning_cout << "Setting number of slices to " << number_of_threads + 1 << "\n";
    io_conf.number_of_slices = number_of_threads + 1;
    io_conf.number_of_repetitions = 1;
  }
  else {
    info_cout << "Using " << number_of_slices << " input slices."
              << "\n";
    io_conf.number_of_repetitions = 1;
  }
  return io_conf;
}

std::unique_ptr<IInputProvider> Allen::make_provider(std::map<std::string, std::string> const& options)
{

  unsigned number_of_slices = 0;
  unsigned events_per_slice = 0;
  std::optional<size_t> n_events;

  // Input file options
  std::string mdf_input = "../input/minbias/mdf/MiniBrunel_2018_MinBias_FTv4_DIGI.mdf";
  std::string mep_input;
  bool mep_layout = true;
  int mpi_window_size = 4;
  bool non_stop = false;
  bool disable_run_changes = 0;

  // MPI options
  bool with_mpi = false;
  std::map<std::string, int> receivers = {{"mem", 1}};

  long number_of_events_requested = 0;

  unsigned number_of_repetitions = 1;
  unsigned number_of_threads = 1;

  // Bank types
  std::unordered_set<BankTypes> bank_types;

  std::string flag, arg;
  const auto flag_in = [&flag](const std::vector<std::string>& option_flags) {
    if (std::find(std::begin(option_flags), std::end(option_flags), flag) != std::end(option_flags)) {
      return true;
    }
    return false;
  };

  // Use flags to populate variables in the program
  for (auto const& entry : options) {
    std::tie(flag, arg) = entry;
    else if (flag_in({"mdf"})) {
      mdf_input = arg;
    }
    else if (flag_in({"mep"})) {
      mep_input = arg;
    }
    else if (flag_in({"transpose-mep"})) {
      mep_layout = !atoi(arg.c_str());
    }
    else if (flag_in({"n", "number-of-events"})) {
      number_of_events_requested = atol(arg.c_str());
    }
    else if (flag_in({"s", "number-of-slices"})) {
      number_of_slices = atoi(arg.c_str());
    }
    else if (flag_in({"t", "threads"})) {
      number_of_threads = atoi(arg.c_str());
      if (number_of_threads > max_stream_threads) {
        error_cout << "Error: more than maximum number of threads (" << max_stream_threads << ") requested\n";
        return {};
      }
    }
    else if (flag_in({"events-per-slice"})) {
      events_per_slice = atoi(arg.c_str());
    }
    else if (flag_in({"b", "bank-types"})) {
      for (auto name : split_string(arg, ",")) {
        auto const bt = bank_type(name);
        if (bt == BankTypes::Unknown) {
          error_cout << "Unknown bank type " << name << "requested.\n";
          return std::unique_ptr<IInputProvider>{};
        }
        else {
          bank_types.emplace(bt);
        }
      }
    }
    else if (flag_in({"with-mpi"})) {
      with_mpi = true;
      bool parsed = false;
      std::tie(parsed, receivers) = parse_receivers(arg);
      if (!parsed) {
        error_cout << "Failed to parse argument to with-mpi\n";
        exit(1);
      }
    }
    else if (flag_in({"mpi-window-size"})) {
      mpi_window_size = atoi(arg.c_str());
    }
    else if (flag_in({"non-stop"})) {
      non_stop = atoi(arg.c_str());
    }
    else if (flag_in({"disable-run-changes"})) {
      disable_run_changes = atoi(arg.c_str());
    }
  }

  // Set a sane default for the number of events per input slice
  if (number_of_events_requested != 0 && events_per_slice > number_of_events_requested) {
    events_per_slice = number_of_events_requested;
  }

  auto io_conf = io_configuration(number_of_slices, number_of_repetitions, number_of_threads);

  if (!mdf_input.empty()) {
    MDFProviderConfig config {false,                     // verify MDF checksums
                              10,                        // number of read buffers
                              4,                         // number of transpose threads
                              events_per_slice * 10 + 1, // maximum number event of offsets in read buffer
                              events_per_slice,          // number of events per read buffer
                              n_io_reps,                 // number of loops over the input files
                              !disable_run_changes};     // Whether to split slices by run number
    return std::make_unique<MDFProvider<
      BankTypes::VP,
      BankTypes::UT,
      BankTypes::FT,
      BankTypes::MUON,
      BankTypes::ODIN,
      BankTypes::ECal,
      BankTypes::HCal>>(number_of_slices, events_per_slice, n_events, split_string(mdf_input, ","), bank_types, config);
  }
  return {};
}
