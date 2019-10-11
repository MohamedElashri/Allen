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

class TTree;
class TFile;

class KalmanChecker : public Checker::BaseChecker {
public:
  struct KalmanTag {
    static std::string const name;
  };

  using subdetector_t = KalmanTag;

  KalmanChecker(CheckerInvoker const* invoker, std::string const& root_file);

  virtual ~KalmanChecker() = default;

  void accumulate(MCEvents const& mc_events, std::vector<Checker::Tracks> const& tracks);

  void report(size_t n_events) const override;

private:
#ifdef WITH_ROOT
  TTree* m_tree = nullptr;
  TFile* m_file = nullptr;
#endif

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
};
