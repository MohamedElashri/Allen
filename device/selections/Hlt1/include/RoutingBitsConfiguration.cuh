/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <cstdint>

namespace RoutingBitsConfiguration {

     struct RoutingBits { 
        int bits_size = 32;  // 32 routing bits for HLT1

        // array of routing bits to be set - test values implemented so far
        // Run 2 routing bits can be found here: https://edms.cern.ch/ui/file/1146861/1.7/rb_note-1.pdf 
        int bits[6] { 33, 
                      34,
                      35,
                      36,
                      47,
                      48 };  

        // expression used to evaluate routing bits - test values implemented so far
        // Run 2 implementation can be found here: https://gitlab.cern.ch/lhcb/Hlt/blob/2018-patches/Hlt%2FHltConf%2Fpython%2FHltConf%2FHltOutput.py#L374 
        std::string expressions[6] { "Hlt1ODINNoBias", 
                                     "Hlt1GECPassthrough",
                                     "Hlt1LowPtMuon",
                                     "Hlt1Passthrough",
                                     "Hlt1KsToPiPi",
                                     "Hlt1GECPassthrough|Hlt1Passthrough" }; 
     }; 
        
     struct AssociatedLines {
       int routing_bit;
       unsigned n_lines;
       int line_numbers[20]; // indices of HLT1 lines used to set each routign bits with an OR logic. For now 20 is a fixed number - will be replaced with the maximum number of lines used in the logic once this is known
     };

} //namespace RoutingBitsConfiguration
