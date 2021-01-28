/*****************************************************************************\
 * (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <string>

#include <MEPProvider.h>
#include <MDFProvider.h>
#include <BinaryProvider.h>
#include <Provider.h>
#include <BankTypes.h>
#include <ProgramOptions.h>

std::unique_ptr<IInputProvider> make_provider(std::map<std::string, std::string> const& options){

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
  size_t n_io_reps = number_of_repetitions;

  std::string file_list;

  // Folder containing raw, MC and muon information
  std::string folder_data = "../input/minbias/";
  const std::string folder_rawdata = "banks/";

  // Set a sane default for the number of events per input slice
  if (number_of_events_requested != 0 && events_per_slice > number_of_events_requested) {
    events_per_slice = number_of_events_requested;
  }

  // Raw data input folders
  const auto folder_name_velopix_raw = folder_data + folder_rawdata + "VP";
  const auto folder_name_UT_raw = folder_data + folder_rawdata + "UT";
  const auto folder_name_SciFi_raw = folder_data + folder_rawdata + "FTCluster";
  const auto folder_name_Muon_raw = folder_data + folder_rawdata + "Muon";
  const auto folder_name_ODIN_raw = folder_data + folder_rawdata + "ODIN";

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
    if (flag_in({"f", "folder"})) {
      folder_data = arg + "/";
    }
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
    else if (flag_in({"events-per-slice"})) {
      events_per_slice = atoi(arg.c_str());
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
    else if (flag_in({"file-list"})) {
      file_list = arg;
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

  if (!mep_input.empty() || with_mpi) {
    MEPProviderConfig config {false,                // verify MEP checksums
                              10,                   // number of read buffers
                              mep_layout ? 1u : 4u, // number of transpose threads
                              mpi_window_size,      // MPI sliding window size
                              with_mpi,             // Receive from MPI or read files
                              non_stop,             // Run the application non-stop
                              !mep_layout,          // MEPs should be transposed to Allen layout
                              !disable_run_changes, // Whether to split slices by run number
                              receivers};           // Map of receiver to MPI rank to receive from

   return std::make_unique<MEPProvider<
      BankTypes::VP,
      BankTypes::UT,
      BankTypes::FT,
      BankTypes::MUON,
      BankTypes::ODIN,
      BankTypes::ECal,
      BankTypes::HCal>>(number_of_slices, events_per_slice, n_events, split_string(mep_input, ","), config);
    return std::make_unique<MEPProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN>>(
           number_of_slices, events_per_slice, n_events, split_string(mep_input, ","), config);
  }
  else if (!mdf_input.empty()) {
    mep_layout = false;
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
      BankTypes::HCal>>(number_of_slices, events_per_slice, n_events, split_string(mdf_input, ","), config);
  }
  else {
    std::vector<std::string> connections = {
      folder_name_velopix_raw, folder_name_UT_raw, folder_name_SciFi_raw, folder_name_Muon_raw, folder_name_ODIN_raw};

    return  std::make_unique<BinaryProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN>>(
            number_of_slices, events_per_slice, n_events, std::move(connections), n_io_reps, file_list);
  }


}
