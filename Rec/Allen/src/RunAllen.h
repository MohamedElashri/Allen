/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#ifndef RUNALLEN_H
#define RUNALLEN_H

// Gaudi includes
#include "GaudiAlg/Transformer.h"

// LHCb includes
#include <Event/ODIN.h>
#include <Event/RawBank.h>
#include <Event/RawEvent.h>

// Rec includes
#include "Event/Track.h"

// Allen includes
#include "Constants.cuh"
#include "RegisterConsumers.h"
#include <Dumpers/IUpdater.h>
#include "HostBuffers.cuh"
#include "HostBuffersManager.cuh"
#include "RuntimeOptions.h"
#include "BankTypes.h"
#include "Stream.h"
#include "Logger.h"
#include <TESProvider.h>
#include <ROOTService.h>

// STL includes
#include <deque>

class RunAllen final : public Gaudi::Functional::MultiTransformerFilter<std::tuple<HostBuffers>(
                         const std::array<TransposedBanks, LHCb::RawBank::types().size()>& allen_banks,
                         const LHCb::ODIN& odin)> {
public:
  /// Standard constructor
  RunAllen(const std::string& name, ISvcLocator* pSvcLocator);

  /// initialization
  StatusCode initialize() override;

  /// initialization
  StatusCode finalize() override;

  /// Algorithm execution
  std::tuple<bool, HostBuffers> operator()(
    const std::array<TransposedBanks, LHCb::RawBank::types().size()>& allen_banks,
    const LHCb::ODIN& odin) const override;

private:
  Constants m_constants;
  std::vector<std::string> m_line_names;
  const unsigned m_number_of_repetitions = 1;
  const bool m_cpu_offload = true;
  const unsigned m_n_buffers = 1;
  const bool m_do_check = true;

  Allen::NonEventData::IUpdater* m_updater = nullptr;

  std::unique_ptr<Stream> m_stream;
  std::unique_ptr<HostBuffersManager> m_host_buffers_manager;
  std::unique_ptr<ROOTService> m_root_service;

  Gaudi::Property<std::string> m_sequence {this, "Sequence", "hlt1_pp_default"};
  Gaudi::Property<std::string> m_updaterName {this, "UpdaterName", "AllenUpdater"};
  Gaudi::Property<std::string> m_paramDir {this, "ParamDir", "${PARAMFILESROOT}"};
  Gaudi::Property<std::string> m_json {this, "JSON", "${ALLEN_INSTALL_DIR}/constants/hlt1_pp_default.json"};
  Gaudi::Property<std::string> m_monitorFile {this, "MonitorFile", "allen_monitor.root"};

  // If set to false, events are only filtered by the GEC
  // If set to true, events are filtered based on an OR of the Allen selection lines
  Gaudi::Property<bool> m_filter_hlt1 {this, "FilterHLT1", false};
  Gaudi::Property<bool> m_filterGEC {this, "FilterGEC", false};

  // Counters for HLT1 selection rates
  mutable std::deque<Gaudi::Accumulators::BinomialCounter<>> m_hlt1_line_rates {};
};

#endif
