/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <cstdio>
#include <KalmanChecker.h>
#include <ROOTHeaders.h>

KalmanChecker::KalmanChecker(CheckerInvoker const* invoker, std::string const& root_file, const std::string& name) :
  m_directory {name}
{
  // Setup the TTree.
  m_file = invoker->root_file(root_file);
  auto* dir = static_cast<TDirectory*>(m_file->Get(name.c_str()));
  if (!dir) {
    dir = m_file->mkdir(name.c_str());
    dir = static_cast<TDirectory*>(m_file->Get(name.c_str()));
  }
  dir->cd();

  // NOTE: This TTree will be cleaned up by ROOT when the file is
  // closed.
  m_tree = new TTree("kalman_ip_tree", "kalman_ip_tree");
  m_tree->Branch("z", &m_trk_z);
  m_tree->Branch("x", &m_trk_x);
  m_tree->Branch("y", &m_trk_y);
  m_tree->Branch("tx", &m_trk_tx);
  m_tree->Branch("ty", &m_trk_ty);
  m_tree->Branch("qop", &m_trk_qop);
  m_tree->Branch("first_qop", &m_trk_first_qop);
  m_tree->Branch("best_qop", &m_trk_best_qop);
  m_tree->Branch("best_pt", &m_trk_best_pt);
  m_tree->Branch("kalman_ip", &m_trk_kalman_ip);
  m_tree->Branch("kalman_ipx", &m_trk_kalman_ipx);
  m_tree->Branch("kalman_ipy", &m_trk_kalman_ipy);
  m_tree->Branch("kalman_ip_chi2", &m_trk_kalman_ip_chi2);
  m_tree->Branch("kalman_docaz", &m_trk_kalman_docaz);
  m_tree->Branch("velo_ip", &m_trk_velo_ip);
  m_tree->Branch("velo_ipx", &m_trk_velo_ipx);
  m_tree->Branch("velo_ipy", &m_trk_velo_ipy);
  m_tree->Branch("velo_ip_chi2", &m_trk_velo_ip_chi2);
  m_tree->Branch("velo_docaz", &m_trk_velo_docaz);
  m_tree->Branch("chi2", &m_trk_chi2);
  m_tree->Branch("chi2V", &m_trk_chi2V);
  m_tree->Branch("chi2T", &m_trk_chi2T);
  m_tree->Branch("ndof", &m_trk_ndof);
  m_tree->Branch("ndofV", &m_trk_ndofV);
  m_tree->Branch("ndofT", &m_trk_ndofT);
  m_tree->Branch("ghost", &m_trk_ghost);
  m_tree->Branch("mcp_p", &m_mcp_p);
}

void KalmanChecker::accumulate(
  MCEvents const& mc_events,
  gsl::span<const Checker::Tracks> tracks,
  gsl::span<const mask_t> event_list)
{
  auto guard = std::scoped_lock {m_mutex};
  for (size_t i = 0; i < event_list.size(); ++i) {
    const auto evnum = event_list[i];
    const auto& event_tracks = tracks[i];
    const auto& mc_event = mc_events[evnum];
    const auto& mcps = mc_event.m_mcps;
    MCAssociator mcassoc {mcps};
    // Loop over tracks.
    for (auto track : event_tracks) {
      const auto assoc =
        mcassoc(std::begin(track.allids), std::begin(track.allids) + track.total_number_of_hits, track.n_matched_total);
      if (!assoc)
        m_trk_ghost = 1.f;
      else {
        const auto weight = std::get<1>(assoc.front());
        if (weight < 0.7f)
          m_trk_ghost = 1.f;
        else {
          m_trk_ghost = 0.f;
          const auto mcp = std::get<0>(assoc.front());
          m_mcp_p = mcp.p;
        }
      }
      m_trk_z = track.z;
      m_trk_x = track.x;
      m_trk_y = track.y;
      m_trk_tx = track.tx;
      m_trk_ty = track.ty;
      m_trk_qop = track.qop;
      m_trk_first_qop = track.first_qop;
      m_trk_best_qop = track.best_qop;
      m_trk_kalman_ip = track.kalman_ip;
      m_trk_kalman_ipx = track.kalman_ipx;
      m_trk_kalman_ipy = track.kalman_ipy;
      m_trk_kalman_ip_chi2 = track.kalman_ip_chi2;
      m_trk_kalman_docaz = track.kalman_docaz;
      m_trk_velo_ip = track.velo_ip;
      m_trk_velo_ipx = track.velo_ipx;
      m_trk_velo_ipy = track.velo_ipy;
      m_trk_velo_ip_chi2 = track.velo_ip_chi2;
      m_trk_velo_docaz = track.velo_docaz;
      m_trk_chi2 = track.chi2;
      m_trk_chi2V = track.chi2V;
      m_trk_chi2T = track.chi2T;
      m_trk_ndof = (float) track.ndof;
      m_trk_ndofV = (float) track.ndofV;
      m_trk_ndofT = (float) track.ndofT;
      float sint =
        std::sqrt((m_trk_tx * m_trk_tx + m_trk_ty * m_trk_ty) / (1.f + m_trk_tx * m_trk_tx + m_trk_ty * m_trk_ty));
      m_trk_best_pt = sint / std::abs(track.best_qop);
      m_tree->Fill();
    }
  }
}

void KalmanChecker::report(size_t) const
{
  auto* dir = m_file->Get<TDirectory>(m_directory.c_str());
  dir->WriteTObject(m_tree);
}
