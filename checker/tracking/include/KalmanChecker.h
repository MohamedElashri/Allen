/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <functional>
#include <set>
#include <string>
#include <vector>
#include <Common.h>
#include <InputTools.h>
#include <CheckerTypes.h>
#include <CheckerInvoker.h>
#include <MCAssociator.h>
#include <MCEvent.h>
#include <algorithm>
#include <mutex>
#include <Datatype.cuh>

class TTree;
class TFile;

class KalmanChecker : public Checker::BaseChecker {
public:
  KalmanChecker(CheckerInvoker const* invoker, std::string const& root_file, const std::string& name);

  virtual ~KalmanChecker() = default;

  void
  accumulate(MCEvents const& mc_events, gsl::span<const Checker::Tracks> tracks, gsl::span<const mask_t> event_list);

  void report(size_t n_events) const override;

private:
  TTree* m_tree = nullptr;
  TFile* m_file = nullptr;

  std::mutex m_mutex;
  float m_trk_z = 0.f;
  float m_trk_x = 0.f;
  float m_trk_y = 0.f;
  float m_trk_tx = 0.f;
  float m_trk_ty = 0.f;
  float m_trk_qop = 0.f;
  float m_trk_first_qop = 0.f;
  float m_trk_best_qop = 0.f;
  float m_trk_best_pt = 0.f;
  float m_trk_kalman_ip = 0.f;
  float m_trk_kalman_ipx = 0.f;
  float m_trk_kalman_ipy = 0.f;
  float m_trk_kalman_ip_chi2 = 0.f;
  float m_trk_kalman_docaz = 0.f;
  float m_trk_velo_ip = 0.f;
  float m_trk_velo_ipx = 0.f;
  float m_trk_velo_ipy = 0.f;
  float m_trk_velo_ip_chi2 = 0.f;
  float m_trk_velo_docaz = 0.f;
  float m_trk_chi2 = 0.f;
  float m_trk_chi2V = 0.f;
  float m_trk_chi2T = 0.f;
  float m_trk_ndof = 0.f;
  float m_trk_ndofV = 0.f;
  float m_trk_ndofT = 0.f;
  float m_trk_ghost = 0.f;
  float m_mcp_p = 0.f;
  float m_trk_velo_hits = 0.f;
  float m_trk_scifi_hits = 0.f;
  float m_trk_ut_hits = 0.f;
  float m_trk_chi2UT = 0.f;

  std::string m_directory;
};
