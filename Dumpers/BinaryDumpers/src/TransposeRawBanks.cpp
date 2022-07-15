/*****************************************************************************\
* (c) Copyright 2000-2021 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <cstring>
#include <fstream>
#include <string>
#include <unordered_map>
#include <vector>

#include <AIDA/IHistogram1D.h>

#include <GaudiAlg/MergingTransformer.h>
#include <GaudiAlg/GaudiHistoAlg.h>
#include <GaudiKernel/GaudiException.h>

#include <Event/ODIN.h>
#include <Event/RawBank.h>
#include <Event/RawEvent.h>

#include <Dumpers/Utils.h>

#include <BankTypes.h>

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
class TransposeRawBanks : public Gaudi::Functional::MergingTransformer<
                            std::array<TransposedBanks, LHCb::RawBank::types().size()>(VOC<LHCb::RawEvent*> const&),
                            Gaudi::Functional::Traits::BaseClass_t<GaudiHistoAlg>> {
public:
  /// Standard constructor
  TransposeRawBanks(const std::string& name, ISvcLocator* pSvcLocator);

  StatusCode initialize() override;

  std::array<TransposedBanks, LHCb::RawBank::types().size()> operator()(
    VOC<LHCb::RawEvent*> const& rawEvents) const override;

private:
  Gaudi::Property<std::set<LHCb::RawBank::BankType>> m_bankTypes {this,
                                                                  "BankTypes",
                                                                  {LHCb::RawBank::VP,
                                                                   LHCb::RawBank::VPRetinaCluster,
                                                                   LHCb::RawBank::UT,
                                                                   LHCb::RawBank::FTCluster,
                                                                   LHCb::RawBank::EcalPacked,
                                                                   LHCb::RawBank::Calo,
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

std::array<TransposedBanks, LHCb::RawBank::types().size()> TransposeRawBanks::operator()(
  VOC<LHCb::RawEvent*> const& rawEvents) const
{

  std::array<TransposedBanks, LHCb::RawBank::types().size()> output;
  std::array<LHCb::RawBank::View, LHCb::RawBank::types().size()> rawBanks;

  for (auto const* rawEvent : rawEvents) {
    if (rawEvent == nullptr) continue;
    std::for_each(m_bankTypes.begin(), m_bankTypes.end(), [this, rawEvent, &rawBanks](auto bt) {
      auto banks = rawEvent->banks(bt);
      if (!banks.empty()) {
        if (rawBanks[bt].empty()) {
          rawBanks[bt] = banks;
        }
        else if (msgLevel(MSG::DEBUG)) {
          debug() << "Multiple RawEvents contain " << toString(bt) << " banks. The first ones found will be used."
                  << endmsg;
        }
      }
    });
  }

  // We have to deal with the fact that calo banks can come in different types
  for (auto bt : m_bankTypes.value()) {
    if (bt == LHCb::RawBank::EcalPacked || bt == LHCb::RawBank::HcalPacked) {
      if (rawBanks[bt].empty() && rawBanks[LHCb::RawBank::Calo].empty()) {
        // Old-style calo banks empty and new-style calo banks also empty
        throw GaudiException {"Cannot find " + toString(bt) + " raw bank.", "", StatusCode::FAILURE};
      }
    }
    else if (bt == LHCb::RawBank::Calo) {
      if (
        rawBanks[bt].empty() &&
        ((m_bankTypes.value().count(LHCb::RawBank::EcalPacked) && rawBanks[LHCb::RawBank::EcalPacked].empty()) ||
         (m_bankTypes.value().count(LHCb::RawBank::HcalPacked) && rawBanks[LHCb::RawBank::HcalPacked].empty()))) {
        // New-style calo banks empty and old-style calo banks also empty
        throw GaudiException {"Cannot find " + toString(bt) + " raw bank.", "", StatusCode::FAILURE};
      }
    }
    else if (rawBanks[bt].empty()) {
      throw GaudiException {"Cannot find " + toString(bt) + " raw bank.", "", StatusCode::FAILURE};
    }
  }

  for (auto bt : LHCb::RawBank::types()) {
    auto const& banks = rawBanks[bt];
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
      bankSizes.push_back(bank->size());
      bankTypes.push_back(static_cast<uint8_t>(bank->type()));
    }

    // Dumping number_of_rawbanks + 1 offsets!
    DumpUtils::Writer bank_buffer;
    bank_buffer.write(nBanks, bankOffsets, bankData);
    output[bt] =
      TransposedBanks {bank_buffer.buffer(), std::move(bankSizes), std::move(bankTypes), banks[0]->version()};
  }
  return output;
}

// Declaration of the Algorithm Factory
DECLARE_COMPONENT(TransposeRawBanks)
