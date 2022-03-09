/*g***************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <cstdint>

namespace RoutingBitsDefinition {
  const std::map<uint32_t, std::string> default_routingbit_map = {
    {33, "^Hlt1.*Lumi.*"}
    // RB 35 Beam-Gas for Velo alignment
    ,
    {35, "Hlt1(?!BeamGasHighRhoVertices)BeamGas.*"} // TODO: place-holder, line needs to be added
    // RB 36 EXPRESS stream (bypasses Hlt2)
    ,
    {36, "Hlt1(Velo.*|BeamGas.*VeloOpen)"}
    // RB 37 Beam-Beam collisions for Velo alignment
    ,
    {37, "Hlt1(TrackMVA|TwoTrackMVA|TwoTrackCatBoost|TrackMuonMVA)"}
    //{37, "Hlt1TrackMVA|Hlt1TwoTrackMVA|Hlt1TwoTrackCatBoost|Hlt1TrackMuonMVA|Hlt1TrackElectronMVA"}
    // RB 40 Velo (closing) monitoring
    ,
    {40, "Hlt1Velo.*"}
    // RB 46 HLT1 physics for monitoring and alignment
    ,
    {46, "Hlt1(?!ODIN)(?!L0)(?!Lumi)(?!Tell1)(?!MB)(?!NZS)(?!Velo)(?!BeamGas)(?!Incident).*"}
    // RB 48 NoBias, prescaled
    ,
    {48, "Hlt1.*NoBias"}
    // RB 49 NoBias empty-empty events for Herschel time alignment
    ,
    {49, "Hlt1NoBiasEmptyEmpty"} // Doesn't correspond to a line so far
    // RB 53 Tracker alignment
    ,
    //{53, "Hlt1Calib(TrackingKPiDetached|HighPTLowMultTrks)"}
    {53, "Hlt1D2KPi"} // TODO: check if Hlt1D2KPi is equivalent to TrackingKPiDetached
    // RB 54 RICH mirror alignment
    ,
    {54, "Hlt1RICH.*Alignment"}
    // RB 56 Muon alignment
    ,
    {56, "Hlt1CalibMuonAlignJpsi"} // TODO: place-holder, line needs to be added
    // RB 57 Tell1 Error events
    ,
    {57, "Hlt1Tell1Error"} // TODO: place-holder, line needs to be added
    // RB 58 DiMuon monitoring events for Herschel
    ,
    {58, "Hlt1LowMultDiMuonMonitor"}}; // TODO: place-holder, line needs to be added

  static constexpr int bits_size = 32; // 32 routing bits for HLT1
  static constexpr int n_words = 4;    // 4 words  (ODIN, HLT1, HLT2, Markus)
} // namespace RoutingBitsDefinition
