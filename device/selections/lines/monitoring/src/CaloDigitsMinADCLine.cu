/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "CaloDigitsMinADCLine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(calo_digits_minADC::calo_digits_minADC_t, calo_digits_minADC::Parameters)

__device__ bool calo_digits_minADC::calo_digits_minADC_t::select(
  const Parameters& parameters,
  std::tuple<const CaloDigit> input)
{
  const auto ecal_digits = std::get<0>(input);
  return ecal_digits.is_valid() && ecal_digits.adc >= parameters.minADC;
}
