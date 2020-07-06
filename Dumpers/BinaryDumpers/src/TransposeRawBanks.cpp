/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the GNU General Public      *
* Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
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

#include <GaudiKernel/ParsersFactory.h>
#include <GaudiAlg/MergingTransformer.h>
#include <AIDA/IHistogram1D.h>
#include <Event/ODIN.h>
#include <Event/RawBank.h>
#include <Event/RawEvent.h>
#include <GaudiAlg/GaudiHistoAlg.h>

#include "Utils.h"

// Parsers are in namespace LHCb for ADL to work.
namespace LHCb {

  StatusCode parse(RawBank::BankType& result, const std::string& in)
  {
    static std::unordered_map<std::string, RawBank::BankType> types;
    if (types.empty()) {
      for (int t = 0; t < RawBank::LastType; ++t) {
        auto bt = static_cast<RawBank::BankType>(t);
        types.emplace(RawBank::typeName(bt), bt);
      }
    }

    // This takes care of quoting
    std::string input;
    using Gaudi::Parsers::parse;
    auto sc = parse(input, in);
    if (!sc) return sc;

    auto it = types.find(input);
    if (it != end(types)) {
      result = it->second;
      return StatusCode::SUCCESS;
    }
    else {
      return StatusCode::FAILURE;
    }
  }

  StatusCode parse(std::set<RawBank::BankType>& s, const std::string& in)
  {
    std::set<std::string> ss;
    using Gaudi::Parsers::parse;
    auto sc = parse(ss, in);
    if (!sc) return sc;
    s.clear();
    try {
      std::transform(begin(ss), end(ss), std::inserter(s, begin(s)), [](const std::string& s) {
        RawBank::BankType t {};
        auto sc = parse(t, s);
        if (!sc) throw GaudiException("Bad Parse", "", sc);
        return t;
      });
    } catch (const GaudiException& ge) {
      return ge.code();
    }
    return StatusCode::SUCCESS;
  }


  inline std::ostream& toStream(const RawBank::BankType& bt, std::ostream& s)
  {
    return s << "'" << RawBank::typeName(bt) << "'";
  }
} // namespace LHCb

template <typename T>
using VOC = Gaudi::Functional::vector_of_const_<T>;

// Raw bank format:
// -----------------------------------------------------------------------------
// name                |  type    |  size [bytes]         | array_size
// =============================================================================
// Once
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// number_of_rawbanks  | uint32_t | 4
// -----------------------------------------------------------------------------
// raw_bank_offset     | uint32_t | number_of_rawbanks * 4
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// for each raw bank:
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// sourceID            | uint32_t | 4                     |
// ------------------------------------------------------------------------------
// bank_data           | char     | variable
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

/** @class TransposeRawBanks TransposeRawBanks.h
 *  Algorithm that dumps raw banks to binary files.
 *
 *  @author Roel Aaij
 *  @date   2018-08-27
 */
class TransposeRawBanks : public Gaudi::Functional::MergingTransformer<
  std::array<std::vector<char>, LHCb::RawBank::LastType>(VOC<LHCb::RawEvent*> const&),
                       Gaudi::Functional::Traits::BaseClass_t<GaudiHistoAlg>> {
public:
  /// Standard constructor
  TransposeRawBanks(const std::string& name, ISvcLocator* pSvcLocator);

  StatusCode initialize() override;

  std::array<std::vector<char>, LHCb::RawBank::LastType> operator()(
    VOC<LHCb::RawEvent*> const& rawEvents) const override;

private:
  Gaudi::Property<std::set<LHCb::RawBank::BankType>> m_bankTypes {
    this,
    "BankTypes",
    {LHCb::RawBank::VP, LHCb::RawBank::UT, LHCb::RawBank::FTCluster, LHCb::RawBank::Muon, LHCb::RawBank::ODIN}};

  std::unordered_map<std::string, AIDA::IHistogram1D*> m_histos;
};

TransposeRawBanks::TransposeRawBanks(const std::string& name, ISvcLocator* pSvcLocator) :
  MergingTransformer(
    name,
    pSvcLocator,
    // Inputs
    KeyValues {"RawEventLocations", {LHCb::RawEventLocation::Default}},
    // Output
    KeyValue {"AllenRawInput", "Allen/Raw/Input"})
{}

StatusCode TransposeRawBanks::initialize()
{
  for (const auto bankType : m_bankTypes) {
    auto tn = LHCb::RawBank::typeName(bankType);
    m_histos[tn] = book1D(tn, -0.5, 603.5, 151);
  }
  return StatusCode::SUCCESS;
}

std::array<std::vector<char>, LHCb::RawBank::LastType> TransposeRawBanks::operator()(
  VOC<LHCb::RawEvent*> const& rawEvents) const
{

  std::array<std::vector<char>, LHCb::RawBank::LastType> output;

  std::unordered_map<LHCb::RawBank::BankType, LHCb::span<LHCb::RawBank const*>> rawBanks;

  for (auto const* rawEvent : rawEvents) {
    std::for_each(m_bankTypes.begin(), m_bankTypes.end(), [rawEvent, &rawBanks] (auto bt) {
        auto banks = rawEvent->banks(bt);
        if (!banks.empty()) {
          rawBanks.emplace(bt, std::move(banks));
        }});
  }

  for (auto const& [bankType, banks] : rawBanks) {
    const uint32_t number_of_rawbanks = banks.size();
    uint32_t offset = 0;

    std::vector<uint32_t> bankOffsets;
    std::vector<uint32_t> bankData;
    bankOffsets.push_back(0);

    for (auto& bank : banks) {
      const uint32_t sourceID = static_cast<uint32_t>(bank->sourceID());
      bankData.push_back(sourceID);

      offset++;

      auto bStart = bank->begin<uint32_t>();
      auto bEnd = bank->end<uint32_t>();

      // Debug/testing histogram with the sizes of the binary data per bank
      auto tn = LHCb::RawBank::typeName(bankType);
      auto hit = m_histos.find(tn);
      if (UNLIKELY(hit == end(m_histos))) {
        warning() << "No histogram booked for bank type " << tn << endmsg;
      }
      else {
        hit->second->fill((bEnd - bStart) * sizeof(uint32_t));
      }

      while (bStart != bEnd) {
        const uint32_t raw_data = *(bStart);
        bankData.push_back(raw_data);

        bStart++;
        offset++;
      }
      bankOffsets.push_back(offset * sizeof(uint32_t));
    }

    // Dumping number_of_rawbanks + 1 offsets!
    DumpUtils::Writer bank_buffer;
    bank_buffer.write(number_of_rawbanks, bankOffsets, bankData);
    output[bankType] = bank_buffer.buffer();
  }
  return output;
}

// Declaration of the Algorithm Factory
DECLARE_COMPONENT(TransposeRawBanks)
