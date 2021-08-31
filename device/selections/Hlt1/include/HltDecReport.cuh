/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"

namespace Hlt1 {
  // Hlt1 TCK.
  constexpr static unsigned int TCK = 0;

  // Task ID.
  constexpr static unsigned int taskID = 1;
} // namespace Hlt1

// Structure for handling the HltDecReport of a single line.
class HltDecReport {

private:
  unsigned int m_decReport = 0;

public:
  enum decReportBits {
    decisionBits = 0,
    errorBitsBits = 1,
    numberOfCandidatesBits = 4,
    executionStageBits = 8,
    intDecisionIDBits = 16
  };

  enum decReportMasks {
    decisionMask = 0x1L,
    errorBitsMask = 0xeL,
    numberOfCandidatesMask = 0xf0L,
    executionStageMask = 0xff00L,
    intDecisionIDMask = 0xffff0000L
  };

  HltDecReport() = default;

  __device__ __host__ HltDecReport(unsigned int report) : m_decReport {report} {}

  // get line decision.
  __device__ __host__ bool decision() const { return (m_decReport & decisionMask) >> decisionBits; }

  // get line decision.
  __device__ __host__ unsigned int decisionID() const { return (m_decReport & intDecisionIDMask) >> intDecisionIDBits; }

  // Set line decision.
  __device__ __host__ void setDecision(const bool dec)
  {
    m_decReport &= ~decisionMask;
    m_decReport |= ((((unsigned int) dec) << decisionBits) & decisionMask);
  }

  // Get line decision.
  __device__ __host__ bool getDecision() { return ((bool) ((m_decReport & decisionMask) >> decisionBits)); }

  // Set the error bits.
  __device__ __host__ void setErrorBits(const unsigned int val)
  {
    m_decReport &= ~errorBitsMask;
    m_decReport |= ((val << errorBitsBits) & errorBitsMask);
  }

  // Set the number of candidates.
  __device__ __host__ void setNumberOfCandidates(const unsigned int noc)
  {
    m_decReport &= ~numberOfCandidatesMask;
    m_decReport |= ((noc << numberOfCandidatesBits) & numberOfCandidatesMask);
  }

  // Set the execution stage.
  __device__ __host__ void setExecutionStage(const unsigned int stage)
  {
    m_decReport &= ~executionStageMask;
    m_decReport |= ((stage << executionStageBits) & executionStageMask);
  }

  // Set the intDecisionID.
  __device__ __host__ void setIntDecisionID(const unsigned int decID)
  {
    m_decReport &= ~intDecisionIDMask;
    m_decReport |= ((decID << intDecisionIDBits) & intDecisionIDMask);
  }

  // Get the DecReport data.
  __device__ __host__ unsigned int getDecReport() { return m_decReport; }

  // Set the dec report.
  __device__ __host__ void setDecReport(unsigned int data) { m_decReport = data; }
};
