#pragma once

#include <vector>
#include "BankTypes.h"

/**
 * @brief Runtime options singleton.
 */
struct RuntimeOptions {
  BanksAndOffsets host_velo_events;
  BanksAndOffsets host_ut_events;
  BanksAndOffsets host_scifi_events;
  BanksAndOffsets host_muon_events;
  BanksAndOffsets host_odin_events;
  uint number_of_events;
  uint number_of_selected_events;
  uint number_of_repetitions;
  bool do_check;
  bool cpu_offload;

  RuntimeOptions() = default;

  RuntimeOptions(
    BanksAndOffsets velo_events,
    BanksAndOffsets ut_events,
    BanksAndOffsets scifi_events,
    BanksAndOffsets muon_events,
    BanksAndOffsets odin_events,
    uint param_number_of_events,
    uint param_number_of_repetitions,
    bool param_do_check,
    bool param_cpu_offload) :
    host_velo_events {std::move(velo_events)},
    host_ut_events {std::move(ut_events)}, host_scifi_events {std::move(scifi_events)}, host_muon_events {std::move(
                                                                                          muon_events)},
    host_odin_events {std::move(odin_events)},
    number_of_events(param_number_of_events), number_of_selected_events(param_number_of_events),
    number_of_repetitions(param_number_of_repetitions), do_check(param_do_check), cpu_offload(param_cpu_offload)
  {}
};
