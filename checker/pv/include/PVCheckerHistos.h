#pragma once
#include <CheckerInvoker.h>
#include <ROOTHeaders.h>

class PVCheckerHistos {
public:
#ifdef WITH_ROOT

  TFile* m_file;
  std::string const m_directory;

#endif

  PVCheckerHistos(CheckerInvoker const* invoker, std::string const& root_file);

  void accumulate(
    std::vector<RecPVInfo> const& vec_all_rec,
    std::vector<double> const& vec_rec_x,
    std::vector<double> const& vec_rec_y,
    std::vector<double> const& vec_rec_z,
    std::vector<double> const& vec_diff_x,
    std::vector<double> const& vec_diff_y,
    std::vector<double> const& vec_diff_z,
    std::vector<double> const& vec_err_x,
    std::vector<double> const& vec_err_y,
    std::vector<double> const& vec_err_z,
    std::vector<int> const& vec_n_trinmcpv,
    std::vector<int> const& vec_n_mcpv,
    std::vector<int> const& vec_mcpv_recd,
    std::vector<int> const& vec_recpv_fake,
    std::vector<int> const& vec_mcpv_mult,
    std::vector<int> const& vec_recpv_mult,
    std::vector<double> const& vec_mcpv_zpos,
    std::vector<double> const& vec_mc_x,
    std::vector<double> const& vec_mc_y,
    std::vector<double> const& vec_mc_z);

  void write();

private:
#ifdef WITH_ROOT
  std::unique_ptr<TTree> m_tree;
  std::unique_ptr<TTree> m_mctree;
  std::unique_ptr<TTree> m_allPV;

  std::unique_ptr<TH1F> eff_vs_z;
  std::unique_ptr<TH1F> eff_vs_mult;
  std::unique_ptr<TH1F> eff_matched_vs_z;
  std::unique_ptr<TH1F> eff_matched_vs_mult;
  std::unique_ptr<TH1F> eff_norm_z;
  std::unique_ptr<TH1F> eff_norm_mult;
  std::unique_ptr<TH1F> fakes_vs_mult;
  std::unique_ptr<TH1F> fakes_norm;

  double m_diff_x = 0.;
  double m_diff_y = 0.;
  double m_diff_z = 0.;
  double m_rec_x = 0.;
  double m_rec_y = 0.;
  double m_rec_z = 0.;
  double m_err_x = 0.;
  double m_err_y = 0.;
  double m_err_z = 0.;
  int m_nmcpv = 0;
  int m_ntrinmcpv = 0;

  double m_mc_x = 0.;
  double m_mc_y = 0.;
  double m_mc_z = 0.;

  double m_x = 0.;
  double m_y = 0.;
  double m_z = 0.;
  float m_errx = 0.;
  float m_erry = 0.;
  float m_errz = 0.;
  bool m_isFake = false;

  int const m_bins_norm_z = 50;
  int const m_bins_norm_mult = 25;
  int const m_bins_fake_mult = 20;
#endif
};
