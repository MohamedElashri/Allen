/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <cstdint>

namespace RoutingBitsDefinition {
  // std::map<unsigned, std::string> routingbit_map = { { 33 , "Hlt1ODINNoBias" }
  //              // RB 35 Beam-Gas for Velo alignment
  //              , {34 , "Hlt1GECPassthrough"}
  //              // RB 36 EXPRESS stream (bypasses Hlt2)
  //              , {35 , "Hlt1LowPtMuon"}
  //              // RB 37 Beam-Beam collisions for Velo alignment
  //              , {36 , "Hlt1Passthrough"}
  //              // RB 40 Velo (closing) monitoring
  //              , {47 , "Hlt1KsToPiPi"}
  //              // RB 46 HLT1 physics for monitoring and alignment
  //              , {48 , "Hlt1GECPassthrough|Hlt1Passthrough"}
  //              };
  std::map<int, std::string> routingbit_map = {
    {33, "Hlt1ODINLumi"}
    // RB 35 Beam-Gas for Velo alignment
    ,
    {35, "Hlt1NoBeam|Hlt1BeamOne|Hlt1BeamTwo|Hlt1BothBeams"} // Hlt1ODINBeamGas?
    // RB 36 EXPRESS stream (bypasses Hlt2)
    ,
    {36, "HLT_PASS_RE('Hlt1(Velo.*|BeamGas.*VeloOpen)Decision')"}
    // RB 37 Beam-Beam collisions for Velo alignment
    ,
    {37, "Hlt1TrackMVATight|Hlt1TwoTrackMVATight|Hlt1TrackMuon|Hlt1TrackMuonMVA"}
    // RB 40 Velo (closing) monitoring
    ,
    {40, "Hlt1VeloMicroBias"}
    // RB 46 HLT1 physics for monitoring and alignment
    ,
    {46, "HLT_PASS_RE('Hlt1(?!ODIN)(?!L0)(?!Lumi)(?!Tell1)(?!MB)(?!NZS)(?!Velo)(?!BeamGas)(?!Incident).*Decision')"}
    // RB 48 NoBias, prescaled
    ,
    {48, "Hlt1ODINNoBias"}
    // RB 49 NoBias empty-empty events for Herschel time alignment
    ,
    {49, "Hlt1NoBiasEmptyEmpty"}
    // RB 50 Passthrough for tests
    ,
    {50, "Hlt1Passthrough"}
    // RB 50 Passthrough for tests
    ,
    {18, "Hlt1Passthrough"}
    // RB 53 Tracker alignment
    ,
    {53, "Hlt1CalibTrackingKPiDetached|Hlt1CalibTrackingKPiDetachedHighPTLowMultTrks"}
    // RB 54 RICH mirror alignment
    ,
    {54, "Hlt1CalibRICH"}
    // RB 56 Muon alignment
    ,
    {56, "Hlt1CalibMuonAlignJpsi"}
    // RB 57 Tell1 Error events
    ,
    {57, "Hlt1Tell1Error"}
    // RB 58 DiMuon monitoring events for Herschel
    ,
    {58, "Hlt1LowMultDiMuonMonitor"}};

  static constexpr int bits_size = 32; // 32 routing bits for HLT1

} // namespace RoutingBitsDefinition
