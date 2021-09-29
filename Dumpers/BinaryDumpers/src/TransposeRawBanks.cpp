/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <cstring>
#include <fstream>
#include <string>
#include <unordered_map>
#include <vector>
#include <GaudiAlg/MergingTransformer.h>
#include <AIDA/IHistogram1D.h>
#include <Event/ODIN.h>
#include <Event/RawBank.h>
#include <Event/RawEvent.h>
#include <GaudiAlg/GaudiHistoAlg.h>
#include "Utils.h"

template<typename T>
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
class TransposeRawBanks
  : public Gaudi::Functional::MergingTransformer<
      std::array<std::tuple<std::vector<char>, int>, LHCb::RawBank::types().size()>(VOC<LHCb::RawEvent*> const&),
      Gaudi::Functional::Traits::BaseClass_t<GaudiHistoAlg>> {
public:
  /// Standard constructor
  TransposeRawBanks(const std::string& name, ISvcLocator* pSvcLocator);

  StatusCode initialize() override;

  std::array<std::tuple<std::vector<char>, int>, LHCb::RawBank::types().size()> operator()(
    VOC<LHCb::RawEvent*> const& rawEvents) const override;

private:
  Gaudi::Property<std::set<LHCb::RawBank::BankType>> m_bankTypes {this,
                                                                  "BankTypes",
                                                                  {LHCb::RawBank::VP,
                                                                   LHCb::RawBank::UT,
                                                                   LHCb::RawBank::FTCluster,
                                                                   LHCb::RawBank::EcalPacked,
                                                                   LHCb::RawBank::Muon,
                                                                   LHCb::RawBank::ODIN}};

  std::array<AIDA::IHistogram1D*, LHCb::RawBank::types().size()> m_histos;
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
  for (auto bt : LHCb::RawBank::types()) {
    m_histos[bt] = (m_bankTypes.value().count(bt) ? book1D(toString(bt), -0.5, 603.5, 151) : nullptr);
  }
  return StatusCode::SUCCESS;
}

std::array<std::tuple<std::vector<char>, int>, LHCb::RawBank::types().size()> TransposeRawBanks::operator()(
  VOC<LHCb::RawEvent*> const& rawEvents) const
{

  std::array<std::tuple<std::vector<char>, int>, LHCb::RawBank::types().size()> output;
  std::array<LHCb::RawBank::View, LHCb::RawBank::types().size()> rawBanks;

  for (auto const* rawEvent : rawEvents) {
    std::for_each(m_bankTypes.begin(), m_bankTypes.end(), [rawEvent, &rawBanks](auto bt) {
      auto banks = rawEvent->banks(bt);
      if (!banks.empty()) rawBanks[bt] = banks;
    });
  }

  for (auto bt : LHCb::RawBank::types()) {
    auto const& banks = rawBanks[bt];
    if (banks.empty()) continue;

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
      auto histo = m_histos[bt];
      if (histo == nullptr) {
        warning() << "No histogram booked for bank type " << toString(bt) << endmsg;
      }
      else {
        histo->fill((bEnd - bStart) * sizeof(uint32_t));
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
    output[bt] = std::tuple {bank_buffer.buffer(), banks[0]->version()};
  }
  return output;
}

// Declaration of the Algorithm Factory
DECLARE_COMPONENT(TransposeRawBanks)
