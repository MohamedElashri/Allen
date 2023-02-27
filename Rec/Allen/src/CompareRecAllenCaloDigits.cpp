/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <string>
#include <vector>

// Gaudi
#include "GaudiAlg/Consumer.h"

// Allen
#include "CaloDigit.cuh"
#include "Logger.h"

// Calorimeter
#include <Event/CaloDigit.h>
#include <Event/CaloDigits_v2.h>

class CompareRecAllenCaloDigits final
  : public Gaudi::Functional::Consumer<void(const std::vector<CaloDigit>&, LHCb::Event::Calo::Digits const&)> {

public:
  /// Standard constructor
  CompareRecAllenCaloDigits(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  void operator()(const std::vector<CaloDigit>&, LHCb::Event::Calo::Digits const&) const override;

private:
  void compare(std::vector<CaloDigit> const& allenDigits, LHCb::Event::Calo::Digits const& lhcbDigits) const;
};

DECLARE_COMPONENT(CompareRecAllenCaloDigits)

CompareRecAllenCaloDigits::CompareRecAllenCaloDigits(const std::string& name, ISvcLocator* pSvcLocator) :
  Consumer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"ecal_digits", ""}, KeyValue {"EcalDigits", LHCb::CaloDigitLocation::Ecal}})
{}

void CompareRecAllenCaloDigits::operator()(
  const std::vector<CaloDigit>& ecal_digits,
  LHCb::Event::Calo::Digits const& ecalDigits) const
{
  for (auto const& [allenDigits, lhcbDigits] : {std::forward_as_tuple(ecal_digits, ecalDigits)}) {
    compare(allenDigits, lhcbDigits);
  }
}

void CompareRecAllenCaloDigits::compare(
  std::vector<CaloDigit> const& allenDigits,
  LHCb::Event::Calo::Digits const& lhcbDigits) const
{

  namespace IndexDetails = LHCb::Detector::Calo::DenseIndex::details;
  unsigned offset = 0;

  for (auto d : lhcbDigits) {
    LHCb::Detector::Calo::Index idx {d.cellID()};
    unsigned digit_index = unsigned {idx} - offset;
    if (d.adc() != allenDigits[digit_index].adc) {
      std::stringstream msg;
      error() << "LHCb digit at " << unsigned {idx} << " has different ADC: " << d.adc() << ", then Allen digit at "
              << digit_index << "with ADC: " << allenDigits[digit_index].adc << endmsg;
    }
  }
}
