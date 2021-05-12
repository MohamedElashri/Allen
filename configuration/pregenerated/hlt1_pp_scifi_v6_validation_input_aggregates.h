/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <tuple>
#include "/Users/dcampora/projects/allen/scripts/..//device/selections/lines/muon/include/DiMuonMassLine.cuh"
#include "/Users/dcampora/projects/allen/scripts/..//device/selections/lines/charm/include/D2KKLine.cuh"
#include "/Users/dcampora/projects/allen/scripts/..//device/selections/lines/muon/include/SingleHighPtMuonLine.cuh"
#include "/Users/dcampora/projects/allen/scripts/..//device/selections/lines/muon/include/TrackMuonMVALine.cuh"
#include "/Users/dcampora/projects/allen/scripts/..//device/selections/lines/charm/include/D2PiPiLine.cuh"
#include "/Users/dcampora/projects/allen/scripts/..//device/selections/lines/monitoring/include/ODINEventTypeLine.cuh"
#include "/Users/dcampora/projects/allen/scripts/..//device/selections/lines/muon/include/LowPtMuonLine.cuh"
#include "/Users/dcampora/projects/allen/scripts/..//device/selections/lines/inclusive_hadron/include/TrackMVALine.cuh"
#include "/Users/dcampora/projects/allen/scripts/..//device/selections/lines/monitoring/include/BeamCrossingLine.cuh"
#include "/Users/dcampora/projects/allen/scripts/..//device/selections/lines/inclusive_hadron/include/TwoTrackMVALine.cuh"
#include "/Users/dcampora/projects/allen/scripts/..//device/selections/lines/calibration/include/PassthroughLine.cuh"
#include "/Users/dcampora/projects/allen/scripts/..//device/selections/lines/muon/include/DiMuonSoftLine.cuh"
#include "/Users/dcampora/projects/allen/scripts/..//device/selections/lines/monitoring/include/VeloMicroBiasLine.cuh"
#include "/Users/dcampora/projects/allen/scripts/..//device/selections/lines/calibration/include/D2KPiLine.cuh"
#include "/Users/dcampora/projects/allen/scripts/..//device/selections/lines/muon/include/LowPtDiMuonLine.cuh"

struct Hlt1TrackMVA__dev_decisions_t : track_mva_line::Parameters::dev_decisions_t {
  using type = track_mva_line::Parameters::dev_decisions_t::type;
  using deps = track_mva_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1TwoTrackMVA__dev_decisions_t : two_track_mva_line::Parameters::dev_decisions_t {
  using type = two_track_mva_line::Parameters::dev_decisions_t::type;
  using deps = two_track_mva_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1SingleHighPtMuon__dev_decisions_t : single_high_pt_muon_line::Parameters::dev_decisions_t {
  using type = single_high_pt_muon_line::Parameters::dev_decisions_t::type;
  using deps = single_high_pt_muon_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1LowPtMuon__dev_decisions_t : low_pt_muon_line::Parameters::dev_decisions_t {
  using type = low_pt_muon_line::Parameters::dev_decisions_t::type;
  using deps = low_pt_muon_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1D2KK__dev_decisions_t : d2kk_line::Parameters::dev_decisions_t {
  using type = d2kk_line::Parameters::dev_decisions_t::type;
  using deps = d2kk_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1D2KPi__dev_decisions_t : d2kpi_line::Parameters::dev_decisions_t {
  using type = d2kpi_line::Parameters::dev_decisions_t::type;
  using deps = d2kpi_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1D2PiPi__dev_decisions_t : d2pipi_line::Parameters::dev_decisions_t {
  using type = d2pipi_line::Parameters::dev_decisions_t::type;
  using deps = d2pipi_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1DiMuonHighMass__dev_decisions_t : di_muon_mass_line::Parameters::dev_decisions_t {
  using type = di_muon_mass_line::Parameters::dev_decisions_t::type;
  using deps = di_muon_mass_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1DiMuonLowMass__dev_decisions_t : di_muon_mass_line::Parameters::dev_decisions_t {
  using type = di_muon_mass_line::Parameters::dev_decisions_t::type;
  using deps = di_muon_mass_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1DiMuonSoft__dev_decisions_t : di_muon_soft_line::Parameters::dev_decisions_t {
  using type = di_muon_soft_line::Parameters::dev_decisions_t::type;
  using deps = di_muon_soft_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1LowPtDiMuon__dev_decisions_t : low_pt_di_muon_line::Parameters::dev_decisions_t {
  using type = low_pt_di_muon_line::Parameters::dev_decisions_t::type;
  using deps = low_pt_di_muon_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1TrackMuonMVA__dev_decisions_t : track_muon_mva_line::Parameters::dev_decisions_t {
  using type = track_muon_mva_line::Parameters::dev_decisions_t::type;
  using deps = track_muon_mva_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1GECPassthrough__dev_decisions_t : passthrough_line::Parameters::dev_decisions_t {
  using type = passthrough_line::Parameters::dev_decisions_t::type;
  using deps = passthrough_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1NoBeam__dev_decisions_t : beam_crossing_line::Parameters::dev_decisions_t {
  using type = beam_crossing_line::Parameters::dev_decisions_t::type;
  using deps = beam_crossing_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1BeamOne__dev_decisions_t : beam_crossing_line::Parameters::dev_decisions_t {
  using type = beam_crossing_line::Parameters::dev_decisions_t::type;
  using deps = beam_crossing_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1BeamTwo__dev_decisions_t : beam_crossing_line::Parameters::dev_decisions_t {
  using type = beam_crossing_line::Parameters::dev_decisions_t::type;
  using deps = beam_crossing_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1BothBeams__dev_decisions_t : beam_crossing_line::Parameters::dev_decisions_t {
  using type = beam_crossing_line::Parameters::dev_decisions_t::type;
  using deps = beam_crossing_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1VeloMicroBias__dev_decisions_t : velo_micro_bias_line::Parameters::dev_decisions_t {
  using type = velo_micro_bias_line::Parameters::dev_decisions_t::type;
  using deps = velo_micro_bias_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1ODINLumi__dev_decisions_t : odin_event_type_line::Parameters::dev_decisions_t {
  using type = odin_event_type_line::Parameters::dev_decisions_t::type;
  using deps = odin_event_type_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1ODINNoBias__dev_decisions_t : odin_event_type_line::Parameters::dev_decisions_t {
  using type = odin_event_type_line::Parameters::dev_decisions_t::type;
  using deps = odin_event_type_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1Passthrough__dev_decisions_t : passthrough_line::Parameters::dev_decisions_t {
  using type = passthrough_line::Parameters::dev_decisions_t::type;
  using deps = passthrough_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1TrackMVA__dev_decisions_offsets_t : track_mva_line::Parameters::dev_decisions_offsets_t {
  using type = track_mva_line::Parameters::dev_decisions_offsets_t::type;
  using deps = track_mva_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1TwoTrackMVA__dev_decisions_offsets_t : two_track_mva_line::Parameters::dev_decisions_offsets_t {
  using type = two_track_mva_line::Parameters::dev_decisions_offsets_t::type;
  using deps = two_track_mva_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1SingleHighPtMuon__dev_decisions_offsets_t : single_high_pt_muon_line::Parameters::dev_decisions_offsets_t {
  using type = single_high_pt_muon_line::Parameters::dev_decisions_offsets_t::type;
  using deps = single_high_pt_muon_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1LowPtMuon__dev_decisions_offsets_t : low_pt_muon_line::Parameters::dev_decisions_offsets_t {
  using type = low_pt_muon_line::Parameters::dev_decisions_offsets_t::type;
  using deps = low_pt_muon_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1D2KK__dev_decisions_offsets_t : d2kk_line::Parameters::dev_decisions_offsets_t {
  using type = d2kk_line::Parameters::dev_decisions_offsets_t::type;
  using deps = d2kk_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1D2KPi__dev_decisions_offsets_t : d2kpi_line::Parameters::dev_decisions_offsets_t {
  using type = d2kpi_line::Parameters::dev_decisions_offsets_t::type;
  using deps = d2kpi_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1D2PiPi__dev_decisions_offsets_t : d2pipi_line::Parameters::dev_decisions_offsets_t {
  using type = d2pipi_line::Parameters::dev_decisions_offsets_t::type;
  using deps = d2pipi_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1DiMuonHighMass__dev_decisions_offsets_t : di_muon_mass_line::Parameters::dev_decisions_offsets_t {
  using type = di_muon_mass_line::Parameters::dev_decisions_offsets_t::type;
  using deps = di_muon_mass_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1DiMuonLowMass__dev_decisions_offsets_t : di_muon_mass_line::Parameters::dev_decisions_offsets_t {
  using type = di_muon_mass_line::Parameters::dev_decisions_offsets_t::type;
  using deps = di_muon_mass_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1DiMuonSoft__dev_decisions_offsets_t : di_muon_soft_line::Parameters::dev_decisions_offsets_t {
  using type = di_muon_soft_line::Parameters::dev_decisions_offsets_t::type;
  using deps = di_muon_soft_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1LowPtDiMuon__dev_decisions_offsets_t : low_pt_di_muon_line::Parameters::dev_decisions_offsets_t {
  using type = low_pt_di_muon_line::Parameters::dev_decisions_offsets_t::type;
  using deps = low_pt_di_muon_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1TrackMuonMVA__dev_decisions_offsets_t : track_muon_mva_line::Parameters::dev_decisions_offsets_t {
  using type = track_muon_mva_line::Parameters::dev_decisions_offsets_t::type;
  using deps = track_muon_mva_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1GECPassthrough__dev_decisions_offsets_t : passthrough_line::Parameters::dev_decisions_offsets_t {
  using type = passthrough_line::Parameters::dev_decisions_offsets_t::type;
  using deps = passthrough_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1NoBeam__dev_decisions_offsets_t : beam_crossing_line::Parameters::dev_decisions_offsets_t {
  using type = beam_crossing_line::Parameters::dev_decisions_offsets_t::type;
  using deps = beam_crossing_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1BeamOne__dev_decisions_offsets_t : beam_crossing_line::Parameters::dev_decisions_offsets_t {
  using type = beam_crossing_line::Parameters::dev_decisions_offsets_t::type;
  using deps = beam_crossing_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1BeamTwo__dev_decisions_offsets_t : beam_crossing_line::Parameters::dev_decisions_offsets_t {
  using type = beam_crossing_line::Parameters::dev_decisions_offsets_t::type;
  using deps = beam_crossing_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1BothBeams__dev_decisions_offsets_t : beam_crossing_line::Parameters::dev_decisions_offsets_t {
  using type = beam_crossing_line::Parameters::dev_decisions_offsets_t::type;
  using deps = beam_crossing_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1VeloMicroBias__dev_decisions_offsets_t : velo_micro_bias_line::Parameters::dev_decisions_offsets_t {
  using type = velo_micro_bias_line::Parameters::dev_decisions_offsets_t::type;
  using deps = velo_micro_bias_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1ODINLumi__dev_decisions_offsets_t : odin_event_type_line::Parameters::dev_decisions_offsets_t {
  using type = odin_event_type_line::Parameters::dev_decisions_offsets_t::type;
  using deps = odin_event_type_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1ODINNoBias__dev_decisions_offsets_t : odin_event_type_line::Parameters::dev_decisions_offsets_t {
  using type = odin_event_type_line::Parameters::dev_decisions_offsets_t::type;
  using deps = odin_event_type_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1Passthrough__dev_decisions_offsets_t : passthrough_line::Parameters::dev_decisions_offsets_t {
  using type = passthrough_line::Parameters::dev_decisions_offsets_t::type;
  using deps = passthrough_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1TrackMVA__host_post_scaler_t : track_mva_line::Parameters::host_post_scaler_t {
  using type = track_mva_line::Parameters::host_post_scaler_t::type;
  using deps = track_mva_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1TwoTrackMVA__host_post_scaler_t : two_track_mva_line::Parameters::host_post_scaler_t {
  using type = two_track_mva_line::Parameters::host_post_scaler_t::type;
  using deps = two_track_mva_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1SingleHighPtMuon__host_post_scaler_t : single_high_pt_muon_line::Parameters::host_post_scaler_t {
  using type = single_high_pt_muon_line::Parameters::host_post_scaler_t::type;
  using deps = single_high_pt_muon_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1LowPtMuon__host_post_scaler_t : low_pt_muon_line::Parameters::host_post_scaler_t {
  using type = low_pt_muon_line::Parameters::host_post_scaler_t::type;
  using deps = low_pt_muon_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1D2KK__host_post_scaler_t : d2kk_line::Parameters::host_post_scaler_t {
  using type = d2kk_line::Parameters::host_post_scaler_t::type;
  using deps = d2kk_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1D2KPi__host_post_scaler_t : d2kpi_line::Parameters::host_post_scaler_t {
  using type = d2kpi_line::Parameters::host_post_scaler_t::type;
  using deps = d2kpi_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1D2PiPi__host_post_scaler_t : d2pipi_line::Parameters::host_post_scaler_t {
  using type = d2pipi_line::Parameters::host_post_scaler_t::type;
  using deps = d2pipi_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1DiMuonHighMass__host_post_scaler_t : di_muon_mass_line::Parameters::host_post_scaler_t {
  using type = di_muon_mass_line::Parameters::host_post_scaler_t::type;
  using deps = di_muon_mass_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1DiMuonLowMass__host_post_scaler_t : di_muon_mass_line::Parameters::host_post_scaler_t {
  using type = di_muon_mass_line::Parameters::host_post_scaler_t::type;
  using deps = di_muon_mass_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1DiMuonSoft__host_post_scaler_t : di_muon_soft_line::Parameters::host_post_scaler_t {
  using type = di_muon_soft_line::Parameters::host_post_scaler_t::type;
  using deps = di_muon_soft_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1LowPtDiMuon__host_post_scaler_t : low_pt_di_muon_line::Parameters::host_post_scaler_t {
  using type = low_pt_di_muon_line::Parameters::host_post_scaler_t::type;
  using deps = low_pt_di_muon_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1TrackMuonMVA__host_post_scaler_t : track_muon_mva_line::Parameters::host_post_scaler_t {
  using type = track_muon_mva_line::Parameters::host_post_scaler_t::type;
  using deps = track_muon_mva_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1GECPassthrough__host_post_scaler_t : passthrough_line::Parameters::host_post_scaler_t {
  using type = passthrough_line::Parameters::host_post_scaler_t::type;
  using deps = passthrough_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1NoBeam__host_post_scaler_t : beam_crossing_line::Parameters::host_post_scaler_t {
  using type = beam_crossing_line::Parameters::host_post_scaler_t::type;
  using deps = beam_crossing_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1BeamOne__host_post_scaler_t : beam_crossing_line::Parameters::host_post_scaler_t {
  using type = beam_crossing_line::Parameters::host_post_scaler_t::type;
  using deps = beam_crossing_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1BeamTwo__host_post_scaler_t : beam_crossing_line::Parameters::host_post_scaler_t {
  using type = beam_crossing_line::Parameters::host_post_scaler_t::type;
  using deps = beam_crossing_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1BothBeams__host_post_scaler_t : beam_crossing_line::Parameters::host_post_scaler_t {
  using type = beam_crossing_line::Parameters::host_post_scaler_t::type;
  using deps = beam_crossing_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1VeloMicroBias__host_post_scaler_t : velo_micro_bias_line::Parameters::host_post_scaler_t {
  using type = velo_micro_bias_line::Parameters::host_post_scaler_t::type;
  using deps = velo_micro_bias_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1ODINLumi__host_post_scaler_t : odin_event_type_line::Parameters::host_post_scaler_t {
  using type = odin_event_type_line::Parameters::host_post_scaler_t::type;
  using deps = odin_event_type_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1ODINNoBias__host_post_scaler_t : odin_event_type_line::Parameters::host_post_scaler_t {
  using type = odin_event_type_line::Parameters::host_post_scaler_t::type;
  using deps = odin_event_type_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1Passthrough__host_post_scaler_t : passthrough_line::Parameters::host_post_scaler_t {
  using type = passthrough_line::Parameters::host_post_scaler_t::type;
  using deps = passthrough_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1TrackMVA__host_post_scaler_hash_t : track_mva_line::Parameters::host_post_scaler_hash_t {
  using type = track_mva_line::Parameters::host_post_scaler_hash_t::type;
  using deps = track_mva_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1TwoTrackMVA__host_post_scaler_hash_t : two_track_mva_line::Parameters::host_post_scaler_hash_t {
  using type = two_track_mva_line::Parameters::host_post_scaler_hash_t::type;
  using deps = two_track_mva_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1SingleHighPtMuon__host_post_scaler_hash_t : single_high_pt_muon_line::Parameters::host_post_scaler_hash_t {
  using type = single_high_pt_muon_line::Parameters::host_post_scaler_hash_t::type;
  using deps = single_high_pt_muon_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1LowPtMuon__host_post_scaler_hash_t : low_pt_muon_line::Parameters::host_post_scaler_hash_t {
  using type = low_pt_muon_line::Parameters::host_post_scaler_hash_t::type;
  using deps = low_pt_muon_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1D2KK__host_post_scaler_hash_t : d2kk_line::Parameters::host_post_scaler_hash_t {
  using type = d2kk_line::Parameters::host_post_scaler_hash_t::type;
  using deps = d2kk_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1D2KPi__host_post_scaler_hash_t : d2kpi_line::Parameters::host_post_scaler_hash_t {
  using type = d2kpi_line::Parameters::host_post_scaler_hash_t::type;
  using deps = d2kpi_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1D2PiPi__host_post_scaler_hash_t : d2pipi_line::Parameters::host_post_scaler_hash_t {
  using type = d2pipi_line::Parameters::host_post_scaler_hash_t::type;
  using deps = d2pipi_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1DiMuonHighMass__host_post_scaler_hash_t : di_muon_mass_line::Parameters::host_post_scaler_hash_t {
  using type = di_muon_mass_line::Parameters::host_post_scaler_hash_t::type;
  using deps = di_muon_mass_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1DiMuonLowMass__host_post_scaler_hash_t : di_muon_mass_line::Parameters::host_post_scaler_hash_t {
  using type = di_muon_mass_line::Parameters::host_post_scaler_hash_t::type;
  using deps = di_muon_mass_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1DiMuonSoft__host_post_scaler_hash_t : di_muon_soft_line::Parameters::host_post_scaler_hash_t {
  using type = di_muon_soft_line::Parameters::host_post_scaler_hash_t::type;
  using deps = di_muon_soft_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1LowPtDiMuon__host_post_scaler_hash_t : low_pt_di_muon_line::Parameters::host_post_scaler_hash_t {
  using type = low_pt_di_muon_line::Parameters::host_post_scaler_hash_t::type;
  using deps = low_pt_di_muon_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1TrackMuonMVA__host_post_scaler_hash_t : track_muon_mva_line::Parameters::host_post_scaler_hash_t {
  using type = track_muon_mva_line::Parameters::host_post_scaler_hash_t::type;
  using deps = track_muon_mva_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1GECPassthrough__host_post_scaler_hash_t : passthrough_line::Parameters::host_post_scaler_hash_t {
  using type = passthrough_line::Parameters::host_post_scaler_hash_t::type;
  using deps = passthrough_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1NoBeam__host_post_scaler_hash_t : beam_crossing_line::Parameters::host_post_scaler_hash_t {
  using type = beam_crossing_line::Parameters::host_post_scaler_hash_t::type;
  using deps = beam_crossing_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1BeamOne__host_post_scaler_hash_t : beam_crossing_line::Parameters::host_post_scaler_hash_t {
  using type = beam_crossing_line::Parameters::host_post_scaler_hash_t::type;
  using deps = beam_crossing_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1BeamTwo__host_post_scaler_hash_t : beam_crossing_line::Parameters::host_post_scaler_hash_t {
  using type = beam_crossing_line::Parameters::host_post_scaler_hash_t::type;
  using deps = beam_crossing_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1BothBeams__host_post_scaler_hash_t : beam_crossing_line::Parameters::host_post_scaler_hash_t {
  using type = beam_crossing_line::Parameters::host_post_scaler_hash_t::type;
  using deps = beam_crossing_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1VeloMicroBias__host_post_scaler_hash_t : velo_micro_bias_line::Parameters::host_post_scaler_hash_t {
  using type = velo_micro_bias_line::Parameters::host_post_scaler_hash_t::type;
  using deps = velo_micro_bias_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1ODINLumi__host_post_scaler_hash_t : odin_event_type_line::Parameters::host_post_scaler_hash_t {
  using type = odin_event_type_line::Parameters::host_post_scaler_hash_t::type;
  using deps = odin_event_type_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1ODINNoBias__host_post_scaler_hash_t : odin_event_type_line::Parameters::host_post_scaler_hash_t {
  using type = odin_event_type_line::Parameters::host_post_scaler_hash_t::type;
  using deps = odin_event_type_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1Passthrough__host_post_scaler_hash_t : passthrough_line::Parameters::host_post_scaler_hash_t {
  using type = passthrough_line::Parameters::host_post_scaler_hash_t::type;
  using deps = passthrough_line::Parameters::host_post_scaler_hash_t::deps;
};

static_assert(all_host_or_all_device_v<Hlt1TrackMVA__dev_decisions_t, track_mva_line::Parameters::dev_decisions_t>);
static_assert(
  all_host_or_all_device_v<Hlt1TwoTrackMVA__dev_decisions_t, two_track_mva_line::Parameters::dev_decisions_t>);
static_assert(all_host_or_all_device_v<
              Hlt1SingleHighPtMuon__dev_decisions_t,
              single_high_pt_muon_line::Parameters::dev_decisions_t>);
static_assert(all_host_or_all_device_v<Hlt1LowPtMuon__dev_decisions_t, low_pt_muon_line::Parameters::dev_decisions_t>);
static_assert(all_host_or_all_device_v<Hlt1D2KK__dev_decisions_t, d2kk_line::Parameters::dev_decisions_t>);
static_assert(all_host_or_all_device_v<Hlt1D2KPi__dev_decisions_t, d2kpi_line::Parameters::dev_decisions_t>);
static_assert(all_host_or_all_device_v<Hlt1D2PiPi__dev_decisions_t, d2pipi_line::Parameters::dev_decisions_t>);
static_assert(
  all_host_or_all_device_v<Hlt1DiMuonHighMass__dev_decisions_t, di_muon_mass_line::Parameters::dev_decisions_t>);
static_assert(
  all_host_or_all_device_v<Hlt1DiMuonLowMass__dev_decisions_t, di_muon_mass_line::Parameters::dev_decisions_t>);
static_assert(
  all_host_or_all_device_v<Hlt1DiMuonSoft__dev_decisions_t, di_muon_soft_line::Parameters::dev_decisions_t>);
static_assert(
  all_host_or_all_device_v<Hlt1LowPtDiMuon__dev_decisions_t, low_pt_di_muon_line::Parameters::dev_decisions_t>);
static_assert(
  all_host_or_all_device_v<Hlt1TrackMuonMVA__dev_decisions_t, track_muon_mva_line::Parameters::dev_decisions_t>);
static_assert(
  all_host_or_all_device_v<Hlt1GECPassthrough__dev_decisions_t, passthrough_line::Parameters::dev_decisions_t>);
static_assert(all_host_or_all_device_v<Hlt1NoBeam__dev_decisions_t, beam_crossing_line::Parameters::dev_decisions_t>);
static_assert(all_host_or_all_device_v<Hlt1BeamOne__dev_decisions_t, beam_crossing_line::Parameters::dev_decisions_t>);
static_assert(all_host_or_all_device_v<Hlt1BeamTwo__dev_decisions_t, beam_crossing_line::Parameters::dev_decisions_t>);
static_assert(
  all_host_or_all_device_v<Hlt1BothBeams__dev_decisions_t, beam_crossing_line::Parameters::dev_decisions_t>);
static_assert(
  all_host_or_all_device_v<Hlt1VeloMicroBias__dev_decisions_t, velo_micro_bias_line::Parameters::dev_decisions_t>);
static_assert(
  all_host_or_all_device_v<Hlt1ODINLumi__dev_decisions_t, odin_event_type_line::Parameters::dev_decisions_t>);
static_assert(
  all_host_or_all_device_v<Hlt1ODINNoBias__dev_decisions_t, odin_event_type_line::Parameters::dev_decisions_t>);
static_assert(
  all_host_or_all_device_v<Hlt1Passthrough__dev_decisions_t, passthrough_line::Parameters::dev_decisions_t>);
static_assert(
  all_host_or_all_device_v<Hlt1TrackMVA__dev_decisions_offsets_t, track_mva_line::Parameters::dev_decisions_offsets_t>);
static_assert(all_host_or_all_device_v<
              Hlt1TwoTrackMVA__dev_decisions_offsets_t,
              two_track_mva_line::Parameters::dev_decisions_offsets_t>);
static_assert(all_host_or_all_device_v<
              Hlt1SingleHighPtMuon__dev_decisions_offsets_t,
              single_high_pt_muon_line::Parameters::dev_decisions_offsets_t>);
static_assert(all_host_or_all_device_v<
              Hlt1LowPtMuon__dev_decisions_offsets_t,
              low_pt_muon_line::Parameters::dev_decisions_offsets_t>);
static_assert(
  all_host_or_all_device_v<Hlt1D2KK__dev_decisions_offsets_t, d2kk_line::Parameters::dev_decisions_offsets_t>);
static_assert(
  all_host_or_all_device_v<Hlt1D2KPi__dev_decisions_offsets_t, d2kpi_line::Parameters::dev_decisions_offsets_t>);
static_assert(
  all_host_or_all_device_v<Hlt1D2PiPi__dev_decisions_offsets_t, d2pipi_line::Parameters::dev_decisions_offsets_t>);
static_assert(all_host_or_all_device_v<
              Hlt1DiMuonHighMass__dev_decisions_offsets_t,
              di_muon_mass_line::Parameters::dev_decisions_offsets_t>);
static_assert(all_host_or_all_device_v<
              Hlt1DiMuonLowMass__dev_decisions_offsets_t,
              di_muon_mass_line::Parameters::dev_decisions_offsets_t>);
static_assert(all_host_or_all_device_v<
              Hlt1DiMuonSoft__dev_decisions_offsets_t,
              di_muon_soft_line::Parameters::dev_decisions_offsets_t>);
static_assert(all_host_or_all_device_v<
              Hlt1LowPtDiMuon__dev_decisions_offsets_t,
              low_pt_di_muon_line::Parameters::dev_decisions_offsets_t>);
static_assert(all_host_or_all_device_v<
              Hlt1TrackMuonMVA__dev_decisions_offsets_t,
              track_muon_mva_line::Parameters::dev_decisions_offsets_t>);
static_assert(all_host_or_all_device_v<
              Hlt1GECPassthrough__dev_decisions_offsets_t,
              passthrough_line::Parameters::dev_decisions_offsets_t>);
static_assert(all_host_or_all_device_v<
              Hlt1NoBeam__dev_decisions_offsets_t,
              beam_crossing_line::Parameters::dev_decisions_offsets_t>);
static_assert(all_host_or_all_device_v<
              Hlt1BeamOne__dev_decisions_offsets_t,
              beam_crossing_line::Parameters::dev_decisions_offsets_t>);
static_assert(all_host_or_all_device_v<
              Hlt1BeamTwo__dev_decisions_offsets_t,
              beam_crossing_line::Parameters::dev_decisions_offsets_t>);
static_assert(all_host_or_all_device_v<
              Hlt1BothBeams__dev_decisions_offsets_t,
              beam_crossing_line::Parameters::dev_decisions_offsets_t>);
static_assert(all_host_or_all_device_v<
              Hlt1VeloMicroBias__dev_decisions_offsets_t,
              velo_micro_bias_line::Parameters::dev_decisions_offsets_t>);
static_assert(all_host_or_all_device_v<
              Hlt1ODINLumi__dev_decisions_offsets_t,
              odin_event_type_line::Parameters::dev_decisions_offsets_t>);
static_assert(all_host_or_all_device_v<
              Hlt1ODINNoBias__dev_decisions_offsets_t,
              odin_event_type_line::Parameters::dev_decisions_offsets_t>);
static_assert(all_host_or_all_device_v<
              Hlt1Passthrough__dev_decisions_offsets_t,
              passthrough_line::Parameters::dev_decisions_offsets_t>);
static_assert(
  all_host_or_all_device_v<Hlt1TrackMVA__host_post_scaler_t, track_mva_line::Parameters::host_post_scaler_t>);
static_assert(
  all_host_or_all_device_v<Hlt1TwoTrackMVA__host_post_scaler_t, two_track_mva_line::Parameters::host_post_scaler_t>);
static_assert(all_host_or_all_device_v<
              Hlt1SingleHighPtMuon__host_post_scaler_t,
              single_high_pt_muon_line::Parameters::host_post_scaler_t>);
static_assert(
  all_host_or_all_device_v<Hlt1LowPtMuon__host_post_scaler_t, low_pt_muon_line::Parameters::host_post_scaler_t>);
static_assert(all_host_or_all_device_v<Hlt1D2KK__host_post_scaler_t, d2kk_line::Parameters::host_post_scaler_t>);
static_assert(all_host_or_all_device_v<Hlt1D2KPi__host_post_scaler_t, d2kpi_line::Parameters::host_post_scaler_t>);
static_assert(all_host_or_all_device_v<Hlt1D2PiPi__host_post_scaler_t, d2pipi_line::Parameters::host_post_scaler_t>);
static_assert(
  all_host_or_all_device_v<Hlt1DiMuonHighMass__host_post_scaler_t, di_muon_mass_line::Parameters::host_post_scaler_t>);
static_assert(
  all_host_or_all_device_v<Hlt1DiMuonLowMass__host_post_scaler_t, di_muon_mass_line::Parameters::host_post_scaler_t>);
static_assert(
  all_host_or_all_device_v<Hlt1DiMuonSoft__host_post_scaler_t, di_muon_soft_line::Parameters::host_post_scaler_t>);
static_assert(
  all_host_or_all_device_v<Hlt1LowPtDiMuon__host_post_scaler_t, low_pt_di_muon_line::Parameters::host_post_scaler_t>);
static_assert(
  all_host_or_all_device_v<Hlt1TrackMuonMVA__host_post_scaler_t, track_muon_mva_line::Parameters::host_post_scaler_t>);
static_assert(
  all_host_or_all_device_v<Hlt1GECPassthrough__host_post_scaler_t, passthrough_line::Parameters::host_post_scaler_t>);
static_assert(
  all_host_or_all_device_v<Hlt1NoBeam__host_post_scaler_t, beam_crossing_line::Parameters::host_post_scaler_t>);
static_assert(
  all_host_or_all_device_v<Hlt1BeamOne__host_post_scaler_t, beam_crossing_line::Parameters::host_post_scaler_t>);
static_assert(
  all_host_or_all_device_v<Hlt1BeamTwo__host_post_scaler_t, beam_crossing_line::Parameters::host_post_scaler_t>);
static_assert(
  all_host_or_all_device_v<Hlt1BothBeams__host_post_scaler_t, beam_crossing_line::Parameters::host_post_scaler_t>);
static_assert(all_host_or_all_device_v<
              Hlt1VeloMicroBias__host_post_scaler_t,
              velo_micro_bias_line::Parameters::host_post_scaler_t>);
static_assert(
  all_host_or_all_device_v<Hlt1ODINLumi__host_post_scaler_t, odin_event_type_line::Parameters::host_post_scaler_t>);
static_assert(
  all_host_or_all_device_v<Hlt1ODINNoBias__host_post_scaler_t, odin_event_type_line::Parameters::host_post_scaler_t>);
static_assert(
  all_host_or_all_device_v<Hlt1Passthrough__host_post_scaler_t, passthrough_line::Parameters::host_post_scaler_t>);
static_assert(
  all_host_or_all_device_v<Hlt1TrackMVA__host_post_scaler_hash_t, track_mva_line::Parameters::host_post_scaler_hash_t>);
static_assert(all_host_or_all_device_v<
              Hlt1TwoTrackMVA__host_post_scaler_hash_t,
              two_track_mva_line::Parameters::host_post_scaler_hash_t>);
static_assert(all_host_or_all_device_v<
              Hlt1SingleHighPtMuon__host_post_scaler_hash_t,
              single_high_pt_muon_line::Parameters::host_post_scaler_hash_t>);
static_assert(all_host_or_all_device_v<
              Hlt1LowPtMuon__host_post_scaler_hash_t,
              low_pt_muon_line::Parameters::host_post_scaler_hash_t>);
static_assert(
  all_host_or_all_device_v<Hlt1D2KK__host_post_scaler_hash_t, d2kk_line::Parameters::host_post_scaler_hash_t>);
static_assert(
  all_host_or_all_device_v<Hlt1D2KPi__host_post_scaler_hash_t, d2kpi_line::Parameters::host_post_scaler_hash_t>);
static_assert(
  all_host_or_all_device_v<Hlt1D2PiPi__host_post_scaler_hash_t, d2pipi_line::Parameters::host_post_scaler_hash_t>);
static_assert(all_host_or_all_device_v<
              Hlt1DiMuonHighMass__host_post_scaler_hash_t,
              di_muon_mass_line::Parameters::host_post_scaler_hash_t>);
static_assert(all_host_or_all_device_v<
              Hlt1DiMuonLowMass__host_post_scaler_hash_t,
              di_muon_mass_line::Parameters::host_post_scaler_hash_t>);
static_assert(all_host_or_all_device_v<
              Hlt1DiMuonSoft__host_post_scaler_hash_t,
              di_muon_soft_line::Parameters::host_post_scaler_hash_t>);
static_assert(all_host_or_all_device_v<
              Hlt1LowPtDiMuon__host_post_scaler_hash_t,
              low_pt_di_muon_line::Parameters::host_post_scaler_hash_t>);
static_assert(all_host_or_all_device_v<
              Hlt1TrackMuonMVA__host_post_scaler_hash_t,
              track_muon_mva_line::Parameters::host_post_scaler_hash_t>);
static_assert(all_host_or_all_device_v<
              Hlt1GECPassthrough__host_post_scaler_hash_t,
              passthrough_line::Parameters::host_post_scaler_hash_t>);
static_assert(all_host_or_all_device_v<
              Hlt1NoBeam__host_post_scaler_hash_t,
              beam_crossing_line::Parameters::host_post_scaler_hash_t>);
static_assert(all_host_or_all_device_v<
              Hlt1BeamOne__host_post_scaler_hash_t,
              beam_crossing_line::Parameters::host_post_scaler_hash_t>);
static_assert(all_host_or_all_device_v<
              Hlt1BeamTwo__host_post_scaler_hash_t,
              beam_crossing_line::Parameters::host_post_scaler_hash_t>);
static_assert(all_host_or_all_device_v<
              Hlt1BothBeams__host_post_scaler_hash_t,
              beam_crossing_line::Parameters::host_post_scaler_hash_t>);
static_assert(all_host_or_all_device_v<
              Hlt1VeloMicroBias__host_post_scaler_hash_t,
              velo_micro_bias_line::Parameters::host_post_scaler_hash_t>);
static_assert(all_host_or_all_device_v<
              Hlt1ODINLumi__host_post_scaler_hash_t,
              odin_event_type_line::Parameters::host_post_scaler_hash_t>);
static_assert(all_host_or_all_device_v<
              Hlt1ODINNoBias__host_post_scaler_hash_t,
              odin_event_type_line::Parameters::host_post_scaler_hash_t>);
static_assert(all_host_or_all_device_v<
              Hlt1Passthrough__host_post_scaler_hash_t,
              passthrough_line::Parameters::host_post_scaler_hash_t>);

namespace gather_selections {
  namespace dev_input_selections_t {
    using tuple_t = std::tuple<
      Hlt1TrackMVA__dev_decisions_t,
      Hlt1TwoTrackMVA__dev_decisions_t,
      Hlt1SingleHighPtMuon__dev_decisions_t,
      Hlt1LowPtMuon__dev_decisions_t,
      Hlt1D2KK__dev_decisions_t,
      Hlt1D2KPi__dev_decisions_t,
      Hlt1D2PiPi__dev_decisions_t,
      Hlt1DiMuonHighMass__dev_decisions_t,
      Hlt1DiMuonLowMass__dev_decisions_t,
      Hlt1DiMuonSoft__dev_decisions_t,
      Hlt1LowPtDiMuon__dev_decisions_t,
      Hlt1TrackMuonMVA__dev_decisions_t,
      Hlt1GECPassthrough__dev_decisions_t,
      Hlt1NoBeam__dev_decisions_t,
      Hlt1BeamOne__dev_decisions_t,
      Hlt1BeamTwo__dev_decisions_t,
      Hlt1BothBeams__dev_decisions_t,
      Hlt1VeloMicroBias__dev_decisions_t,
      Hlt1ODINLumi__dev_decisions_t,
      Hlt1ODINNoBias__dev_decisions_t,
      Hlt1Passthrough__dev_decisions_t>;
  }
} // namespace gather_selections
namespace gather_selections {
  namespace dev_input_selections_offsets_t {
    using tuple_t = std::tuple<
      Hlt1TrackMVA__dev_decisions_offsets_t,
      Hlt1TwoTrackMVA__dev_decisions_offsets_t,
      Hlt1SingleHighPtMuon__dev_decisions_offsets_t,
      Hlt1LowPtMuon__dev_decisions_offsets_t,
      Hlt1D2KK__dev_decisions_offsets_t,
      Hlt1D2KPi__dev_decisions_offsets_t,
      Hlt1D2PiPi__dev_decisions_offsets_t,
      Hlt1DiMuonHighMass__dev_decisions_offsets_t,
      Hlt1DiMuonLowMass__dev_decisions_offsets_t,
      Hlt1DiMuonSoft__dev_decisions_offsets_t,
      Hlt1LowPtDiMuon__dev_decisions_offsets_t,
      Hlt1TrackMuonMVA__dev_decisions_offsets_t,
      Hlt1GECPassthrough__dev_decisions_offsets_t,
      Hlt1NoBeam__dev_decisions_offsets_t,
      Hlt1BeamOne__dev_decisions_offsets_t,
      Hlt1BeamTwo__dev_decisions_offsets_t,
      Hlt1BothBeams__dev_decisions_offsets_t,
      Hlt1VeloMicroBias__dev_decisions_offsets_t,
      Hlt1ODINLumi__dev_decisions_offsets_t,
      Hlt1ODINNoBias__dev_decisions_offsets_t,
      Hlt1Passthrough__dev_decisions_offsets_t>;
  }
} // namespace gather_selections
namespace gather_selections {
  namespace host_input_post_scale_factors_t {
    using tuple_t = std::tuple<
      Hlt1TrackMVA__host_post_scaler_t,
      Hlt1TwoTrackMVA__host_post_scaler_t,
      Hlt1SingleHighPtMuon__host_post_scaler_t,
      Hlt1LowPtMuon__host_post_scaler_t,
      Hlt1D2KK__host_post_scaler_t,
      Hlt1D2KPi__host_post_scaler_t,
      Hlt1D2PiPi__host_post_scaler_t,
      Hlt1DiMuonHighMass__host_post_scaler_t,
      Hlt1DiMuonLowMass__host_post_scaler_t,
      Hlt1DiMuonSoft__host_post_scaler_t,
      Hlt1LowPtDiMuon__host_post_scaler_t,
      Hlt1TrackMuonMVA__host_post_scaler_t,
      Hlt1GECPassthrough__host_post_scaler_t,
      Hlt1NoBeam__host_post_scaler_t,
      Hlt1BeamOne__host_post_scaler_t,
      Hlt1BeamTwo__host_post_scaler_t,
      Hlt1BothBeams__host_post_scaler_t,
      Hlt1VeloMicroBias__host_post_scaler_t,
      Hlt1ODINLumi__host_post_scaler_t,
      Hlt1ODINNoBias__host_post_scaler_t,
      Hlt1Passthrough__host_post_scaler_t>;
  }
} // namespace gather_selections
namespace gather_selections {
  namespace host_input_post_scale_hashes_t {
    using tuple_t = std::tuple<
      Hlt1TrackMVA__host_post_scaler_hash_t,
      Hlt1TwoTrackMVA__host_post_scaler_hash_t,
      Hlt1SingleHighPtMuon__host_post_scaler_hash_t,
      Hlt1LowPtMuon__host_post_scaler_hash_t,
      Hlt1D2KK__host_post_scaler_hash_t,
      Hlt1D2KPi__host_post_scaler_hash_t,
      Hlt1D2PiPi__host_post_scaler_hash_t,
      Hlt1DiMuonHighMass__host_post_scaler_hash_t,
      Hlt1DiMuonLowMass__host_post_scaler_hash_t,
      Hlt1DiMuonSoft__host_post_scaler_hash_t,
      Hlt1LowPtDiMuon__host_post_scaler_hash_t,
      Hlt1TrackMuonMVA__host_post_scaler_hash_t,
      Hlt1GECPassthrough__host_post_scaler_hash_t,
      Hlt1NoBeam__host_post_scaler_hash_t,
      Hlt1BeamOne__host_post_scaler_hash_t,
      Hlt1BeamTwo__host_post_scaler_hash_t,
      Hlt1BothBeams__host_post_scaler_hash_t,
      Hlt1VeloMicroBias__host_post_scaler_hash_t,
      Hlt1ODINLumi__host_post_scaler_hash_t,
      Hlt1ODINNoBias__host_post_scaler_hash_t,
      Hlt1Passthrough__host_post_scaler_hash_t>;
  }
} // namespace gather_selections
