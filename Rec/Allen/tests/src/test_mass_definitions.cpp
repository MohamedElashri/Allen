/***************************************************************************** \
 * (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration      *
 *                                                                             *
 * This software is distributed under the terms of the GNU General Public      *
 * Licence version 5 (GPL Version 3), copied verbatim in the file "COPYING".   *
 *                                                                             *
 * In applying this licence, CERN does not waive the privileges and immunities *
 * granted to it by virtue of its status as an Intergovernmental Organization  *
 * or submit itself to any jurisdiction.                                       *
 \*****************************************************************************/

#define BOOST_TEST_MODULE example   
#include <boost/test/unit_test.hpp>

#include "MassDefinitions.h"
#include "Kernel/TrackDefaultParticles.h"

/**
   Checks that particle mass definitions in Allen/main/include/MassDefinitions.h
   are the same as in LHCb/Kernel/TrackDefaultParticles.h
 */

BOOST_AUTO_TEST_CASE( test_mass_definitions ) { 
  constexpr float lhcb_mEl = LHCb::Tr::PID::Electron().mass();
  BOOST_CHECK_EQUAL( Allen::mEl, lhcb_mEl );

  constexpr float lhcb_mMu = LHCb::Tr::PID::Muon().mass();
  BOOST_CHECK_EQUAL( Allen::mMu, lhcb_mMu );

  constexpr float lhcb_mPi = LHCb::Tr::PID::Pion().mass();
  BOOST_CHECK_EQUAL( Allen::mPi, lhcb_mPi );

  constexpr float lhcb_mK = LHCb::Tr::PID::Kaon().mass();
  BOOST_CHECK_EQUAL( Allen::mK, lhcb_mK );

  constexpr float lhcb_mP = LHCb::Tr::PID::Proton().mass();
  BOOST_CHECK_EQUAL( Allen::mP, lhcb_mP );
}
