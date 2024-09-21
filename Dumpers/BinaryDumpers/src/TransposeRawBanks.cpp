/*****************************************************************************\
* (c) Copyright 2000-2021 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <cstring>
#include <fstream>
#include <string>
#include <unordered_map>
#include <vector>
#include <array>

#include "Gaudi/Accumulators/Histogram.h"

#include <GaudiAlg/MergingTransformer.h>
#include <GaudiKernel/GaudiException.h>
#include <Gaudi/Parsers/Factory.h>

#include <Event/ODIN.h>
#include <Event/RawBank.h>
#include <Event/RawEvent.h>

#include <Dumpers/Utils.h>

#include <BankTypes.h>
#include <BankMapping.h>

template<typename T>
using VOC = Gaudi::Functional::vector_of_const_<T>;

// Raw bank format:
// -----------------------------------------------------------------------------
// name                |  type    |  size [bytes]         | array_size
// =============================================================================
// Once
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// number_of_rawbanks  | uint32_t | 4
// raw_bank_offset     | uint32_t | number_of_rawbanks * 4
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// -----------------------------------------------------------------------------
// for each raw bank:
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// sourceID            | uint32_t | 4                     |
// ------------------------------------------------------------------------------
// bank_data           | char     | variable
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

std::string toString(BankTypes e) { return bank_name(e); }
std::ostream& toStream(BankTypes e, std::ostream& os) { return os << std::quoted(toString(e), '\''); }
std::ostream& operator<<(std::ostream& s, BankTypes e) { return toStream(e, s); }

StatusCode parse(BankTypes& bt, const std::string& in)
{
  auto s = std::string_view {in};
  if (!s.empty() && s.front() == s.back() && (s.front() == '\'' || s.front() == '\"')) {
    s.remove_prefix(1);
    s.remove_suffix(1);
  }
  // Use BankSizes here because it has all he BankTypes as keys.
  auto i = std::find_if(BankSizes.begin(), BankSizes.end(), [s](auto e) { return s == bank_name(std::get<0>(e)); });
  if (i == BankSizes.end()) return StatusCode::FAILURE;
  bt = i->first;
  return StatusCode::SUCCESS;
}

namespace Gaudi::Parsers {
  StatusCode parse(std::set<BankTypes>& s, const std::string& in)
  {
    s.clear();
    using Gaudi::Parsers::parse;
    std::set<std::string> ss;
    return parse(ss, in).andThen([&]() -> StatusCode {
      try {
        std::transform(begin(ss), end(ss), std::inserter(s, begin(s)), [](const std::string& str) {
          BankTypes t {};
          parse(t, str).orThrow("Bad Parse", "");
          return t;
        });
        return StatusCode::SUCCESS;
      } catch (const GaudiException& e) {
        return e.code();
      }
    });
  }
} // namespace Gaudi::Parsers

namespace {
  bool check_top5(BankTypes bt, LHCb::RawBank const* bank)
  {
    auto const sys = static_cast<SourceIdSys>(SourceId_sys(bank->sourceID()));
    auto it = Allen::subdetectors.find(sys);
    return it != Allen::subdetectors.end() && it->second == bt;
  }
} // namespace

/** @class TransposeRawBanks TransposeRawBanks.h
 *  Algorithm that dumps raw banks to binary files.
 *
 *  @author Roel Aaij
 *  @date   2018-08-27
 */
class TransposeRawBanks : public Gaudi::Functional::MergingTransformer<std::array<TransposedBanks, NBankTypes>(
                            VOC<LHCb::RawBank::View> const&)> {
public:
  /// Standard constructor
  TransposeRawBanks(const std::string& name, ISvcLocator* pSvcLocator);

  StatusCode initialize() override;

  std::array<TransposedBanks, NBankTypes> operator()(VOC<LHCb::RawBank::View> const& rawEvents) const override;

private:
  Gaudi::Property<std::set<BankTypes>> m_bankTypes {this,
                                                    "BankTypes",
                                                    {BankTypes::VP,
                                                     BankTypes::UT,
                                                     BankTypes::FT,
                                                     BankTypes::MUON,
                                                     BankTypes::ODIN,
                                                     BankTypes::Rich1,
                                                     BankTypes::Rich2,
                                                     BankTypes::ECal,
                                                     BankTypes::Plume}};

  std::array<std::unique_ptr<Gaudi::Accumulators::Histogram<1>>, NBankTypes> m_histos;

  std::unordered_map<BankTypes, std::unordered_set<LHCb::RawBank::BankType>> m_mapping;
};

TransposeRawBanks::TransposeRawBanks(const std::string& name, ISvcLocator* pSvcLocator) :
  MergingTransformer(
    name,
    pSvcLocator,
    // Inputs
    KeyValues {"RawBankLocations", {LHCb::RawEventLocation::Default}},
    // Output
    KeyValue {"AllenRawInput", "Allen/Raw/Input"})
{}

StatusCode TransposeRawBanks::initialize()
{
  using Axis1D = Gaudi::Accumulators::Axis<double>;

  for (auto const& [lhcb_type, bank_types] : Allen::bank_mapping) {
    for (auto bt : bank_types) {
      m_mapping[bt].insert(lhcb_type);
    }
  }

  for (auto bt : m_bankTypes.value()) {
    if (!m_mapping.count(bt)) {
      error() << "Cannot find appropriate LHCb::RawBank::BankType(s) for Allen BankType " << bank_name(bt) << endmsg;
      return StatusCode::FAILURE;
    }
  }

  for (size_t i = 0; i < NBankTypes; ++i) {
    auto bt = static_cast<BankTypes>(i);
    if (m_bankTypes.value().count(bt)) {
      auto bn = bank_name(bt);
      m_histos[to_integral(bt)] =
        std::make_unique<Gaudi::Accumulators::Histogram<1>>(this, bn, bn, Axis1D {151, -0.5, 603.5});
    }
  }

  return StatusCode::SUCCESS;
}

std::array<TransposedBanks, NBankTypes> TransposeRawBanks::operator()(VOC<LHCb::RawBank::View> const& allBanks) const
{
  std::array<TransposedBanks, NBankTypes> output;
  std::array<std::vector<LHCb::RawBank const*>, NBankTypes> rawBanks;

  for (auto banks : allBanks) {
    std::for_each(m_bankTypes.begin(), m_bankTypes.end(), [banks, &rawBanks](auto bt) {
      auto const bt_idx = to_integral(bt);
      if (!banks.empty()) {
        // For the Calo and Rich, use the top5 bits of the source ID
        // to determine which banks to add. This will take care of
        // splitting Calo banks into ECal and HCal and Rich into
        // Rich1 and Rich2.
        std::function<bool(BankTypes bt, LHCb::RawBank const* bank)> pred;
        // In a RawBank::View all banks have the same type
        auto const lhcb_type = banks[0]->type();
        auto lhcb_it = Allen::bank_mapping.find(lhcb_type);
        if (lhcb_it != Allen::bank_mapping.end() && lhcb_it->second.size() > 1) {
          pred = check_top5;
        }
        else {
          pred = [](BankTypes, LHCb::RawBank const*) { return true; };
        }
        for (auto bank : banks) {
          if (pred(bt, bank)) {
            rawBanks[bt_idx].emplace_back(bank);
          }
        }
      }

      // Default comparison for sorting is by source ID
      std::function<bool(LHCb::RawBank const* a, LHCb::RawBank const* b)> compare =
        [](LHCb::RawBank const* a, LHCb::RawBank const* b) { return a->sourceID() < b->sourceID(); };
      if (bt == BankTypes::VP) {
        auto const& banks = rawBanks[bt_idx];
        if (
          std::any_of(
            banks.begin(), banks.end(), [](LHCb::RawBank const* bank) { return bank->type() == LHCb::RawBank::VP; }) &&
          std::any_of(banks.begin(), banks.end(), [](LHCb::RawBank const* bank) {
            return bank->type() == LHCb::RawBank::VPRetinaCluster;
          })) {
          // Sort VP banks first by bank type and then by source ID to partition in VP and VPRetinaCluster banks.
          compare = [](LHCb::RawBank const* a, LHCb::RawBank const* b) {
            return a->type() == b->type() ? a->sourceID() < b->sourceID() : a->type() < b->type();
          };
        }
      }
      // Sort banks
      std::sort(rawBanks[bt_idx].begin(), rawBanks[bt_idx].end(), compare);
    });
  }

  for (auto bt : m_bankTypes) {
    auto const& banks = rawBanks[to_integral(bt)];
    if (banks.empty()) continue;

    const uint32_t nBanks = banks.size();
    uint32_t offset = 0;

    std::vector<uint32_t> bankOffsets;
    bankOffsets.push_back(0);
    std::vector<uint16_t> bankSizes;
    bankSizes.reserve(nBanks);
    std::vector<uint8_t> bankTypes;
    bankTypes.reserve(nBanks);

    std::vector<uint32_t> bankData;
    bankData.reserve(std::accumulate(banks.begin(), banks.end(), 0, [](int sum, const LHCb::RawBank* const b) {
      return sum + (b->size() + sizeof(unsigned) - 1) / sizeof(unsigned);
    }));

    for (auto& bank : banks) {
      const uint32_t sourceID = static_cast<uint32_t>(bank->sourceID());
      bankData.push_back(sourceID);
      offset++;

      auto bStart = bank->begin<uint32_t>();
      auto bEnd = bank->end<uint32_t>() + (bank->size() % sizeof(uint32_t) != 0);

      // Debug/testing histogram with the sizes of the binary data per bank
      if (m_histos[to_integral(bt)]) {
        ++(*m_histos[to_integral(bt)])[(bEnd - bStart) * sizeof(uint32_t)];
      }
      else {
        warning() << "No histogram booked for bank type " << toString(bt) << endmsg;
      }

      while (bStart != bEnd) {
        const uint32_t raw_data = *(bStart);
        bankData.push_back(raw_data);

        bStart++;
        offset++;
      }
      bankOffsets.push_back(offset * sizeof(uint32_t));
      bankSizes.push_back(bank->size());
      bankTypes.push_back(static_cast<uint8_t>(bank->type()));
    }

    // Dumping number_of_rawbanks + 1 offsets!
    DumpUtils::Writer bank_buffer;
    bank_buffer.write(nBanks, bankOffsets, bankData);
    output[to_integral(bt)] =
      TransposedBanks {bank_buffer.buffer(), std::move(bankSizes), std::move(bankTypes), banks[0]->version()};
  }
  return output;
}

// Declaration of the Algorithm Factory
DECLARE_COMPONENT(TransposeRawBanks)
