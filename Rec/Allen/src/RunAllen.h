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
#include "InputTools.h"
#include "InputReader.h"
#include "RegisterConsumers.h"
#include <Dumpers/IUpdater.h>
#include "HostBuffers.cuh"
#include "HostBuffersManager.cuh"
#include "RuntimeOptions.h"
#include "BankTypes.h"
#include "Stream.h"
#include "Logger.h"
#include "TESProvider.h"

// STL includes
#include <deque>

class RunAllen final
  : public Gaudi::Functional::MultiTransformerFilter<std::tuple<HostBuffers>(
      const std::array<std::tuple<std::vector<char>, int>, LHCb::RawBank::types().size()>& allen_banks,
      const LHCb::ODIN& odin)> {
public:
  /// Standard constructor
  RunAllen(const std::string& name, ISvcLocator* pSvcLocator);

  /// initialization
  StatusCode initialize() override;

  /// Algorithm execution
  std::tuple<bool, HostBuffers> operator()(
    const std::array<std::tuple<std::vector<char>, int>, LHCb::RawBank::types().size()>& allen_banks,
    const LHCb::ODIN& odin) const override;

private:
  Constants m_constants;
  std::vector<std::string> m_line_names;
  const unsigned m_number_of_repetitions = 1;
  const bool m_cpu_offload = true;
  const unsigned m_n_buffers = 1;
  const bool m_do_check = true;

  std::unique_ptr<Stream> m_stream;
  std::unique_ptr<HostBuffersManager> m_host_buffers_manager;
  std::shared_ptr<TESProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN>>
    m_tes_input_provider;

  Gaudi::Property<std::string> m_sequence {this, "Sequence", "hlt1_pp_default"};

  Gaudi::Property<std::string> m_updaterName {this, "UpdaterName", "AllenUpdater"};

  Gaudi::Property<std::string> m_json {this, "JSON", "${ALLEN_INSTALL_DIR}/constants/hlt1_pp_default.json"};
  Gaudi::Property<std::string> m_paramDir {this, "ParamDir", "${ALLEN_PROJECT_ROOT}/input/parameters"};

  // If set to false, events are only filtered by the GEC
  // If set to true, events are filtered based on an OR of the Allen selection lines
  Gaudi::Property<bool> m_filter_hlt1 {this, "FilterHLT1", false};
  Gaudi::Property<bool> m_filterGEC {this, "FilterGEC", false};

  // Counters for HLT1 selection rates
  mutable std::deque<Gaudi::Accumulators::BinomialCounter<>> m_hlt1_line_rates {};
};

#endif
