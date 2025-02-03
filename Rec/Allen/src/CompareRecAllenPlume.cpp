/***************************************************************************** \
 * (c) Copyright 2000-2023 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <string>
#include <vector>
#include <ostream>
#include <map>

// Gaudi
#include "GaudiAlg/Consumer.h"
#include "Gaudi/Accumulators.h"

// Allen
#include "Plume.cuh"

// PLUME
#include <Event/PlumeAdc.h>

class CompareRecAllenPlume final : public Gaudi::Functional::Consumer<
                                     void(std::vector<Plume_, std::allocator<Plume_>> const&, LHCb::PlumeAdcs const&)> {

public:
  /// Standard constructor
  CompareRecAllenPlume(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  void operator()(std::vector<Plume_, std::allocator<Plume_>> const&, LHCb::PlumeAdcs const&) const override;

private:
  void compare(std::vector<Plume_, std::allocator<Plume_>> const& allenDigits, LHCb::PlumeAdcs const& lhcbDigits) const;

  Gaudi::Property<int> m_pedestalOffset {this, "PedestalOffset", 256, "Offset to subtract from raw ADC counts."};
  std::map<unsigned int, unsigned int> m_map_reversed;

  mutable Gaudi::Accumulators::Counter<> m_matched {this, "Matched HLT1/HLT2 ADC values"};
  mutable Gaudi::Accumulators::Counter<> m_error {this, "Not Matched HLT1/HLT2 ADC values"};
  mutable Gaudi::Accumulators::Counter<> m_matched_ovr {this, "Matched HLT1/HLT2 over-threshold bits"};
  mutable Gaudi::Accumulators::Counter<> m_error_ovr {this, "Not Matched HLT1/HLT2 over-threshold bits"};
};

DECLARE_COMPONENT(CompareRecAllenPlume)

CompareRecAllenPlume::CompareRecAllenPlume(const std::string& name, ISvcLocator* pSvcLocator) :
  Consumer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"plume_digits_Allen", ""}, KeyValue {"plume_digits_Moore", LHCb::PlumeAdcLocation::Default}})
{

  std::transform(
    LHCb::Plume::lumiFebToLogicalChannel.begin(),
    LHCb::Plume::lumiFebToLogicalChannel.end(),
    std::inserter(m_map_reversed, m_map_reversed.end()),
    [](const auto& pair) { return std::make_pair(pair.second, pair.first); });
}

void CompareRecAllenPlume::operator()(
  std::vector<Plume_, std::allocator<Plume_>> const& plume_digits_Allen,
  LHCb::PlumeAdcs const& plume_digits_Moore) const
{
  for (auto const& [allenDigits, lhcbDigits] : {std::forward_as_tuple(plume_digits_Allen, plume_digits_Moore)}) {
    compare(allenDigits, lhcbDigits);
  }
}

void CompareRecAllenPlume::compare(
  std::vector<Plume_, std::allocator<Plume_>> const& allenDigits,
  LHCb::PlumeAdcs const& lhcbDigits) const
{

  for (auto lhcb_digit : lhcbDigits) {
    if (lhcb_digit->channelID().channelType() != LHCb::Detector::Plume::ChannelID::ChannelType::LUMI) continue;
    // only LUMI channels are decoded in Allen, so comparing those only
    if (m_map_reversed.find(lhcb_digit->channelID().channelID()) == m_map_reversed.end()) {
      error() << "LHCb digit " << lhcb_digit->channelID().channelID() << " not found." << endmsg;
      ++m_error;
    }

    int idx_int = m_map_reversed.at(lhcb_digit->channelID().channelID());
    const auto feb = idx_int < 22 ? 0 : 1;
    const auto n_ovt = idx_int - (feb * 32);
    bool ovt = ((allenDigits[0].ovr_th[feb] & (1 << (n_ovt))) >> (n_ovt));

    if (feb == 1) idx_int -= 10;
    auto allen_adc = std::round(allenDigits[0].ADC_counts[idx_int]) - m_pedestalOffset;

    if (lhcb_digit->adc() == allen_adc)
      ++m_matched;
    else {
      ++m_error;
      error() << "ADC " << idx_int << " different at: LHCb " << lhcb_digit->adc() << ", Allen " << allen_adc << endmsg;
    }

    if (lhcb_digit->overThreshold() == ovt)
      ++m_matched_ovr;
    else {
      ++m_error_ovr;
      error() << "OverThreshold bit " << idx_int << " different at: LHCb " << lhcb_digit->overThreshold() << ", Allen "
              << ovt << endmsg;
    }
  } // loop on  digits
}
