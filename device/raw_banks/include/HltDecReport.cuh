/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"

  // Structure for handling the HltDecReport of a single line.
class HltDecReport {    
    
private:
  unsigned int m_decReport = 0;
  
public:
  __device__ __host__ HltDecReport() {}
  __device__ __host__ ~HltDecReport() {}

  enum decReportBits{
    decisionBits = 0,
    errorBitsBits = 1,
    numberOfCandidatesBits = 4,
    executionStageBits = 8,
    intDecisionIDBits = 16
  };
    
  enum decReportMasks{
    decisionMask = 0x1L,
    errorBitsMask = 0xeL,
    numberOfCandidatesMask = 0xf0L,
    executionStageMask = 0xff00L,
    intDecisionIDMask = 0xffff0000L
  };
    
    // Set line decision.
  __device__ __host__ void setDecision(bool dec)
  {
    m_decReport &= ~decisionMask;
    if (dec) {
      m_decReport |= ((((unsigned int)1) << decisionBits) & decisionMask);
    }
  }

  // Set the error bits.
  __device__ __host__ void setErrorBits(unsigned int val)
  {
    m_decReport &= ~errorBitsMask;
    m_decReport |= ((val << errorBitsBits) & errorBitsMask);
  }

  // Set the number of candidates.
  __device__ __host__ void setNumberOfCandidates(unsigned int noc)
  {
    m_decReport &= ~numberOfCandidatesMask;
    m_decReport |= ((noc << numberOfCandidatesBits) & numberOfCandidatesMask);
  }
  
  // Set the execution stage.
  __device__ __host__ void setExecutionStage(unsigned int stage)
  {
    m_decReport &= ~executionStageMask;
    m_decReport |= ((stage << executionStageBits) & executionStageMask);
  }
  
  // Set the intDecisionID.
  __device__ __host__ void setIntDecisionID(unsigned int decID)
  {
    m_decReport &= ~intDecisionIDMask;
    m_decReport |= ((decID << intDecisionIDBits) & intDecisionIDMask);
  }
  
  // Get the DecReport data.
  __device__ __host__ unsigned int getDecReport()
  {
    return m_decReport;
  }
  
};
