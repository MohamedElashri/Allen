/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "CompositeParticleLine.cuh"
#include "MassDefinitions.h"
#include "AllenMonitoring.h"

namespace lambda2ppi_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    DEVICE_OUTPUT(L_M_t, float) L_M;
    DEVICE_OUTPUT(p_P_t, float) p_P;
    DEVICE_OUTPUT(p_PT_t, float) p_PT;
    DEVICE_OUTPUT(p_MIPCHI2_t, float) p_MIPCHI2;
    DEVICE_OUTPUT(p_MIP_t, float) p_MIP;
    DEVICE_OUTPUT(p_CHI2NDF_t, float) p_CHI2NDF;
    DEVICE_OUTPUT(p_Q_t, float) p_Q;
    DEVICE_OUTPUT(pi_P_t, float) pi_P;
    DEVICE_OUTPUT(pi_PT_t, float) pi_PT;
    DEVICE_OUTPUT(pi_MIPCHI2_t, float) pi_MIPCHI2;
    DEVICE_OUTPUT(pi_MIP_t, float) pi_MIP;
    DEVICE_OUTPUT(pi_CHI2NDF_t, float) pi_CHI2NDF;
    DEVICE_OUTPUT(pi_Q_t, float) pi_Q;
    DEVICE_OUTPUT(p_pi_DOCA_t, float) p_pi_DOCA;
    DEVICE_OUTPUT(L_PT_t, float) L_PT;
    DEVICE_OUTPUT(L_VCHI2_t, float) L_VCHI2;
    DEVICE_OUTPUT(L_VZ_t, float) L_VZ;
    DEVICE_OUTPUT(L_BPVVDCHI2_t, float) L_BPVVDCHI2;
    DEVICE_OUTPUT(L_BPVVDZ_t, float) L_BPVVDZ;
    DEVICE_OUTPUT(L_BPVVDRHO_t, float) L_BPVVDRHO;
    DEVICE_OUTPUT(L_BPVDIRA_t, float) L_BPVDIRA;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct lambda2ppi_line_t : public SelectionAlgorithm,
                             Parameters,
                             CompositeParticleLine<lambda2ppi_line_t, Parameters> {

    struct DeviceProperties {
      float L_p_MIPCHI2_min;
      float L_pi_MIPCHI2_min;
      float L_p_MIP_min;
      float L_pi_MIP_min;
      float L_p_PT_min;
      float L_pi_PT_min;
      float L_DOCA_max;
      float L_PT_min;
      float L_M_max;
      float L_VCHI2_max;
      float L_VZ_min;
      float L_VZ_max;
      float L_BPVVDCHI2_min;
      float L_BPVVDZ_min;
      float L_BPVVDRHO_min;
      float L_BPVDIRA_min;
      float minPVZ;
      float maxPVZ;
      Allen::Monitoring::Histogram<>::DeviceType histogram_lz_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_lz_pt;
      Allen::Monitoring::Histogram<>::DeviceType histogram_lz_svz;
      Allen::Monitoring::Histogram<>::DeviceType histogram_lz_pvz;
      DeviceProperties(const lambda2ppi_line_t& algo, const Allen::Context& ctx) :
        L_p_MIPCHI2_min(algo.m_L_p_MIPCHI2_min), L_pi_MIPCHI2_min(algo.m_L_pi_MIPCHI2_min),
        L_p_MIP_min(algo.m_L_p_MIP_min), L_pi_MIP_min(algo.m_L_pi_MIP_min), L_p_PT_min(algo.m_L_p_PT_min),
        L_pi_PT_min(algo.m_L_pi_PT_min), L_DOCA_max(algo.m_L_DOCA_max), L_PT_min(algo.m_L_PT_min),
        L_M_max(algo.m_L_M_max), L_VCHI2_max(algo.m_L_VCHI2_max), L_VZ_min(algo.m_L_VZ_min), L_VZ_max(algo.m_L_VZ_max),
        L_BPVVDCHI2_min(algo.m_L_BPVVDCHI2_min), L_BPVVDZ_min(algo.m_L_BPVVDZ_min),
        L_BPVVDRHO_min(algo.m_L_BPVVDRHO_min), L_BPVDIRA_min(algo.m_L_BPVDIRA_min), minPVZ(algo.m_minPVZ),
        maxPVZ(algo.m_maxPVZ), histogram_lz_mass(algo.m_histogram_lz_mass.data(ctx)),
        histogram_lz_pt(algo.m_histogram_lz_pt.data(ctx)), histogram_lz_svz(algo.m_histogram_lz_svz.data(ctx)),
        histogram_lz_pvz(algo.m_histogram_lz_pvz.data(ctx))
      {}
    };

    __device__ static bool
    select(const Parameters&, const DeviceProperties&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle>,
      unsigned,
      bool);

    __device__ static void monitor(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle>,
      unsigned,
      bool);

    using monitoring_types = std::tuple<
      L_M_t,
      p_P_t,
      p_PT_t,
      p_MIPCHI2_t,
      p_MIP_t,
      p_CHI2NDF_t,
      p_Q_t,
      pi_P_t,
      pi_PT_t,
      pi_MIPCHI2_t,
      pi_MIP_t,
      pi_CHI2NDF_t,
      pi_Q_t,
      L_VCHI2_t,
      p_pi_DOCA_t,
      L_PT_t,
      L_BPVVDCHI2_t,
      L_BPVVDZ_t,
      L_BPVVDRHO_t,
      L_BPVDIRA_t,
      L_VZ_t,
      evtNo_t,
      runNo_t>;

  private:
    Allen::Property<float> m_L_p_MIPCHI2_min {this, "L_p_MIPCHI2_min", 12.f, "proton min ip chi^2 for Lambda LL"};
    Allen::Property<float> m_L_pi_MIPCHI2_min {this, "L_pi_MIPCHI2_min", 32.f, "pion min ip chi^2 for Lambda LL"};
    Allen::Property<float> m_L_p_MIP_min {this, "L_p_MIP_min", 80.f * Allen::Units::um, "proton min ip for Lambda LL"};
    Allen::Property<float> m_L_pi_MIP_min {this, "L_pi_MIP_min", 200.f * Allen::Units::um, "pion min ip for Lambda LL"};
    Allen::Property<float> m_L_p_PT_min {this, "L_p_PT_min", 450.f * Allen::Units::MeV, "proton min pT for Lambda LL"};
    Allen::Property<float> m_L_pi_PT_min {this, "L_pi_PT_min", 80.f * Allen::Units::MeV, "pion min pT for Lambda LL"};
    Allen::Property<float> m_L_DOCA_max {this, "L_DOCA_max", 500.f * Allen::Units::um, "max p, pi DOCA for Lambda LL"};
    Allen::Property<float> m_L_PT_min {this, "L_PT_min", 500.f * Allen::Units::MeV, "min pT of Lambda LL"};
    Allen::Property<float> m_L_M_max {this, "L_M_max", 1140.f * Allen::Units::MeV, "max mass for Lambda LL"};
    Allen::Property<float> m_L_VCHI2_max {this, "L_VCHI2_max", 16.f, "max p pi vertex chi2"};
    Allen::Property<float> m_L_VZ_min {this,
                                       "L_VZ_min",
                                       -80.f * Allen::Units::mm,
                                       "min vertex z position of Lambda candidate"};
    Allen::Property<float> m_L_VZ_max {this,
                                       "L_VZ_max",
                                       650.f * Allen::Units::mm,
                                       "max vertex z position of Lambda candidate"};
    Allen::Property<float> m_L_BPVVDCHI2_min {this,
                                              "L_BPVVDCHI2_min",
                                              180.f,
                                              "min flight distance chi2 between p pi vertex and its best PV"};
    Allen::Property<float> m_L_BPVVDZ_min {this,
                                           "L_BPVVDZ_min",
                                           12.f * Allen::Units::mm,
                                           "min distance (in z) between Lambda vertex and best PV"};
    Allen::Property<float> m_L_BPVVDRHO_min {this,
                                             "L_BPVVDRHO_min",
                                             2.f * Allen::Units::mm,
                                             "min squared radial vertex distance of Lambda w.r.t. its best PV"};
    Allen::Property<float> m_L_BPVDIRA_min {this,
                                            "L_BPVDIRA_min",
                                            0.9997,
                                            "min cosine of direction angle of Lambda w.r.t. its best PV"};
    Allen::Property<float> m_minPVZ {this, "minPVZ", -200.f * Allen::Units::mm, "minimum PV z coordinate"};
    Allen::Property<float> m_maxPVZ {this, "maxPVZ", 200.f * Allen::Units::mm, "maximum PV z coordinate"};

    Allen::Monitoring::Histogram<> m_histogram_lz_mass {this, "lz_mass", "mass", {100u, 1000.f, 1200.f}};
    Allen::Monitoring::Histogram<> m_histogram_lz_pt {this, "lz_pt", "pT (lz)", {100u, 0.f, 1e4f}};
    Allen::Monitoring::Histogram<> m_histogram_lz_svz {this, "lz_svz", "SVz (lz)", {100u, -550.f, 1000.f}};
    Allen::Monitoring::Histogram<> m_histogram_lz_pvz {this, "lz_pvz", "PVz (lz)", {100u, -550.f, -300.f}};
  };
} // namespace lambda2ppi_line
