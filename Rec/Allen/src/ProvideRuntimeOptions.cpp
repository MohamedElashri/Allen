/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
 *                                                                             *
 * This software is distributed under the terms of the GNU General Public      *
 * Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
 *                                                                             *
 * In applying this licence, CERN does not waive the privileges and immunities *
 * granted to it by virtue of its status as an Intergovernmental Organization  *
 * or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <array>

// Gaudi
#include <GaudiAlg/Transformer.h>
#include <Event/RawBank.h>
#include <RuntimeOptions.h>

// Allen
#include <TESProvider.h>
#include <ROOTService.h>
#include <Constants.cuh>
#include <Logger.h>

class ProvideRuntimeOptions final
  : public Gaudi::Functional::Transformer<RuntimeOptions(
      std::array<std::tuple<std::vector<char>, std::vector<uint16_t>, int>, LHCb::RawBank::LastType> const&)> {

public:
  /// Standard constructor
  ProvideRuntimeOptions(const std::string& name, ISvcLocator* pSvcLocator);

  StatusCode initialize() override;

  /// Algorithm execution
  RuntimeOptions operator()(
    std::array<std::tuple<std::vector<char>, std::vector<uint16_t>, int>, LHCb::RawBank::LastType> const& allen_banks)
    const override;

private:
  Gaudi::Property<std::string> m_monitorFile {this, "MonitorFile", "allen_monitor.root"};

  std::unique_ptr<ROOTService> m_root_service {};
};

ProvideRuntimeOptions::ProvideRuntimeOptions(const std::string& name, ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"AllenBanksLocation", "Allen/Raw/Banks"}},
    // Output
    KeyValue {"RuntimeOptionsLocation", "Allen/Stream/RuntimeOptions"})
{}

StatusCode ProvideRuntimeOptions::initialize()
{
  return Transformer::initialize().andThen(
    [&] { m_root_service = std::make_unique<ROOTService>(m_monitorFile.value()); });
}

RuntimeOptions ProvideRuntimeOptions::operator()(
  std::array<std::tuple<std::vector<char>, std::vector<uint16_t>, int>, LHCb::RawBank::LastType> const& allen_banks)
  const
{
  const unsigned number_of_repetitions = 1;
  const bool do_check = false;
  const bool cpu_offload = true;
  const bool param_inject_mem_fail = false;
  const size_t n_slices = 1;
  const size_t events_per_slice = 1;
  const unsigned event_start = 0;
  const unsigned event_end = 1;
  auto tes_provider = std::make_shared<TESProvider>(n_slices, events_per_slice, event_end - event_start);
  tes_provider->set_banks(allen_banks);

  // initialize RuntimeOptions
  const size_t slice_index = 0;
  const bool mep_layout = false;

  return {tes_provider,
          slice_index,
          {event_start, event_end},
          number_of_repetitions,
          do_check,
          cpu_offload,
          mep_layout,
          param_inject_mem_fail,
          nullptr,
          m_root_service.get()};
}

DECLARE_COMPONENT(ProvideRuntimeOptions)
