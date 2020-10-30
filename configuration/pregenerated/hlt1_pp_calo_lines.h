/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include <tuple>
#include "../../device/selections/Hlt1/include/LineTraverser.cuh"
#include "../../device/selections/lines/include/ErrorEventLine.cuh"
#include "../../device/selections/lines/include/PassThroughLine.cuh"
#include "../../device/selections/lines/include/NoBeamsLine.cuh"
#include "../../device/selections/lines/include/BeamOneLine.cuh"
#include "../../device/selections/lines/include/BeamTwoLine.cuh"
#include "../../device/selections/lines/include/BothBeamsLine.cuh"
#include "../../device/selections/lines/include/ODINNoBiasLine.cuh"
#include "../../device/selections/lines/include/ODINLumiLine.cuh"
#include "../../device/selections/lines/include/GECPassthroughLine.cuh"
#include "../../device/selections/lines/include/VeloMicroBiasLine.cuh"
#include "../../device/selections/lines/include/TrackMVALine.cuh"
#include "../../device/selections/lines/include/TrackMuonMVALine.cuh"
#include "../../device/selections/lines/include/SingleHighPtMuonLine.cuh"
#include "../../device/selections/lines/include/LowPtMuonLine.cuh"
#include "../../device/selections/lines/include/TwoTrackMVALine.cuh"
#include "../../device/selections/lines/include/DiMuonHighMassLine.cuh"
#include "../../device/selections/lines/include/DiMuonLowMassLine.cuh"
#include "../../device/selections/lines/include/LowPtDiMuonLine.cuh"
#include "../../device/selections/lines/include/DiMuonSoftLine.cuh"
#include "../../device/selections/lines/include/D2KPiLine.cuh"
#include "../../device/selections/lines/include/D2PiPiLine.cuh"
#include "../../device/selections/lines/include/D2KKLine.cuh"

using configured_lines_t = std::tuple<ErrorEvent::ErrorEvent_t, PassThrough::PassThrough_t, NoBeams::NoBeams_t, BeamOne::BeamOne_t, BeamTwo::BeamTwo_t, BothBeams::BothBeams_t, ODINNoBias::ODINNoBias_t, ODINLumi::ODINLumi_t, GECPassthrough::GECPassthrough_t, VeloMicroBias::VeloMicroBias_t, TrackMVA::TrackMVA_t, TrackMuonMVA::TrackMuonMVA_t, SingleHighPtMuon::SingleHighPtMuon_t, LowPtMuon::LowPtMuon_t, TwoTrackMVA::TwoTrackMVA_t, DiMuonHighMass::DiMuonHighMass_t, DiMuonLowMass::DiMuonLowMass_t, LowPtDiMuon::LowPtDiMuon_t, DiMuonSoft::DiMuonSoft_t, D2KPi::D2KPi_t, D2PiPi::D2PiPi_t, D2KK::D2KK_t>;
