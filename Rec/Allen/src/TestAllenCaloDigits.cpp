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
  : public Gaudi::Functional::Consumer<
      void(HostBuffers const&, LHCb::Event::Calo::Digits const&, LHCb::Event::Calo::Digits const&)> {

public:
  /// Standard constructor
  TestAllenCaloDigits(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  void operator()(const HostBuffers&, LHCb::Event::Calo::Digits const&, LHCb::Event::Calo::Digits const&)
    const override;

private:
  void compare(
    gsl::span<CaloDigit> const& allenDigits,
    LHCb::Event::Calo::Digits const& lhcbDigits,
    std::string const& calo) const;
};

DECLARE_COMPONENT(TestAllenCaloDigits)

TestAllenCaloDigits::TestAllenCaloDigits(const std::string& name, ISvcLocator* pSvcLocator) :
  Consumer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"AllenOutput", "Allen/Out/HostBuffers"},
     KeyValue {"EcalDigits", LHCb::CaloDigitLocation::Ecal},
     KeyValue {"HcalDigits", LHCb::CaloDigitLocation::Hcal}})
{}

void TestAllenCaloDigits::operator()(
  HostBuffers const& hostBuffers,
  LHCb::Event::Calo::Digits const& ecalDigits,
  LHCb::Event::Calo::Digits const& hcalDigits) const
{
  if (hostBuffers.host_number_of_selected_events == 0) return;

  // Processing a single event, the first offset should be the same as
  // the size of the digits container.
  assert(hostBuffers.host_ecal_digits_offsets[1] == hostBuffers.host_ecal_digits.size());
  assert(hostBuffers.host_hcal_digits_offsets[1] == hostBuffers.host_hcal_digits.size());

  std::string const ecal {"Ecal"}, hcal {"Hcal"};

  for (auto const& [allenDigits, lhcbDigits, calo] :
       {std::forward_as_tuple(hostBuffers.host_ecal_digits, ecalDigits, ecal),
        std::forward_as_tuple(hostBuffers.host_hcal_digits, hcalDigits, hcal)}) {
    compare(allenDigits, lhcbDigits, calo);
  }
}

void TestAllenCaloDigits::compare(
  gsl::span<CaloDigit> const& allenDigits,
  LHCb::Event::Calo::Digits const& lhcbDigits,
  std::string const& calo) const
{

  namespace IndexDetails = LHCb::Calo::DenseIndex::details;
  unsigned int hcalOuterOffset =
    IndexDetails::Constants<CaloCellCode::CaloIndex::HcalCalo, IndexDetails::Area::Outer>::global_offset;
  unsigned offset = calo[0] == 'E' ? 0 : hcalOuterOffset;

  for (auto d : lhcbDigits) {
    LHCb::Calo::Index idx {d.cellID()};
    unsigned digit_index = unsigned {idx} - offset;
    if (d.adc() != allenDigits[digit_index].adc) {
      std::stringstream msg;
      error() << "LHCb digit at " << unsigned {idx} << " has different ADC: " << d.adc() << ", then Allen digit at "
              << digit_index << "with ADC: " << allenDigits[digit_index].adc << endmsg;
    }
  }
}
