/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <string>

// Gaudi
#include "GaudiAlg/Consumer.h"

// Allen
#include "HostBuffers.cuh"
#include "CaloDigit.cuh"
#include "Logger.h"

// Calorimeter
#include <Event/CaloDigit.h>
#include <Event/CaloDigits_v2.h>

class TestAllenCaloDigits final
  : public Gaudi::Functional::Consumer<void(HostBuffers const&, LHCb::Event::Calo::Digits const&)> {

public:
  /// Standard constructor
  TestAllenCaloDigits(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  void operator()(const HostBuffers&, LHCb::Event::Calo::Digits const&) const override;

private:
  void compare(gsl::span<CaloDigit> const& allenDigits, LHCb::Event::Calo::Digits const& lhcbDigits) const;
};

DECLARE_COMPONENT(TestAllenCaloDigits)

TestAllenCaloDigits::TestAllenCaloDigits(const std::string& name, ISvcLocator* pSvcLocator) :
  Consumer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"AllenOutput", "Allen/Out/HostBuffers"}, KeyValue {"EcalDigits", LHCb::CaloDigitLocation::Ecal}})
{}

void TestAllenCaloDigits::operator()(HostBuffers const& hostBuffers, LHCb::Event::Calo::Digits const& ecalDigits) const
{
  if (hostBuffers.host_number_of_selected_events == 0) return;

  // Processing a single event, the first offset should be the same as
  // the size of the digits container.
  assert(hostBuffers.host_ecal_digits_offsets[1] == hostBuffers.host_ecal_digits.size());

  for (auto const& [allenDigits, lhcbDigits] : {std::forward_as_tuple(hostBuffers.host_ecal_digits, ecalDigits)}) {
    compare(allenDigits, lhcbDigits);
  }
}

void TestAllenCaloDigits::compare(gsl::span<CaloDigit> const& allenDigits, LHCb::Event::Calo::Digits const& lhcbDigits)
  const
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
