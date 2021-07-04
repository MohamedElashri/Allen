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
#include <Constants.cuh>
#include <Logger.h>

class ProvideRuntimeOptions final : public Gaudi::Functional::Transformer<RuntimeOptions(
                                      std::array<std::tuple<std::vector<char>, int>, LHCb::RawBank::LastType> const&)> {

public:
  /// Standard constructor
  ProvideRuntimeOptions(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  RuntimeOptions operator()(std::array<std::tuple<std::vector<char>, int>, LHCb::RawBank::LastType> const& allen_banks) const override;

private:
  const unsigned m_number_of_repetitions = 1;
  const bool m_do_check = false;
  const bool m_cpu_offload = true;
  const bool m_param_inject_mem_fail = false;
  mutable CheckerInvoker m_checker_invoker {};
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

RuntimeOptions ProvideRuntimeOptions::operator()(
  std::array<std::tuple<std::vector<char>,int>, LHCb::RawBank::LastType> const& allen_banks) const
{
  // bankTypes = {BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN}
  const size_t n_slices = 1;
  const size_t events_per_slice = 1;
  const unsigned event_start = 0;
  const unsigned event_end = 1;
  auto tes_provider =
    std::make_shared<TESProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN,
      BankTypes::ECal,
      BankTypes::HCal>>(
      n_slices, events_per_slice, event_end - event_start);
  tes_provider->set_banks(allen_banks);

  // initialize RuntimeOptions
  const size_t slice_index = 0;
  const bool mep_layout = false;
  MCEvents mc_events;

  return {tes_provider,
          slice_index,
          {event_start, event_end},
          m_number_of_repetitions,
          m_do_check,
          m_cpu_offload,
          mep_layout,
          m_param_inject_mem_fail,
          std::move(mc_events),
          &m_checker_invoker};
}

DECLARE_COMPONENT(ProvideRuntimeOptions)
