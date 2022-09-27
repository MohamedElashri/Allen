/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once
#include <CheckerInvoker.h>
#include <ROOTHeaders.h>

class PVCheckerHistos {
public:
  TFile* m_file;
  std::string const m_directory;

  PVCheckerHistos(CheckerInvoker const* invoker, std::string const& root_file, std::string const& directory);

  void accumulate(
    gsl::span<const RecPVInfo> vec_all_rec,
    gsl::span<const double> vec_rec_x,
    gsl::span<const double> vec_rec_y,
    gsl::span<const double> vec_rec_z,
    gsl::span<const double> vec_diff_x,
    gsl::span<const double> vec_diff_y,
    gsl::span<const double> vec_diff_z,
    gsl::span<const double> vec_err_x,
    gsl::span<const double> vec_err_y,
    gsl::span<const double> vec_err_z,
    gsl::span<const int> vec_n_trinmcpv,
    gsl::span<const int> vec_n_mcpv,
    gsl::span<const int> vec_mcpv_recd,
    gsl::span<const int> vec_recpv_fake,
    gsl::span<const int> vec_mcpv_mult,
    gsl::span<const int> vec_recpv_mult,
    gsl::span<const double> vec_mcpv_zpos,
    gsl::span<const double> vec_mc_x,
    gsl::span<const double> vec_mc_y,
    gsl::span<const double> vec_mc_z);

  void write();

private:
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
};
