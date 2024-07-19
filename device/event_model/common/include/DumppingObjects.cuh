/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#pragma once

namespace Allen::DumppingObjects {

  struct DownstreamParticle {
    // state
    float x, y, z, tx, ty, g, qop, chi2, ghost_prob;
    // PV
    float ip, pvx, pvy, pvz;
    // More
    float px, py, pz, pt, p, eta, rho;
    // Lepton ID
    float is_muon, is_electron;
  };
  struct DownstreamComposite {
    // Basics
    float x, y, z, px, py, pz;
    // More
    float armenteros_x, armenteros_y;
    float quality;
    // PV
    float pvx, pvy, pvz;
    // External
    float ip, doca;
    // More
    float fd, ctau, dz, drho, eta, mcor, minip, minp, minpt, maxp, maxpt, dira;
    // Daughters
    DownstreamParticle dA, dB;
  };
} // namespace Allen::DumppingObjects