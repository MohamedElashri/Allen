/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <cstdint>

namespace RoutingBitsConfiguration {

     struct RoutingBits { 

        // array of routing bits to be set
        int bits[6] { 33, 
                      34,
                      35,
                      36,
                      47,
                      48 };  

        // expression used to evaluate routing bits
        std::string expressions[6] { "Hlt1ODINLumi", 
                                     "Hlt1GECPassthrough",
                                     "Hlt1LowPtMuon",
                                     "Hlt1Passthrough",
                                     "Hlt1KsToPiPi",
                                     "Hlt1GECPassthrough|Hlt1Passthrough" }; 
     }; 
        
     struct AssociatedLines {
       int routing_bit;
       unsigned n_lines;
       int line_numbers[20]; //20 is a fixed number, see if you can replace it 
     };

} //namespace RoutingBitsConfiguration
