/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#ifndef ROUTINGBITS_H
#define ROUTINGBITS_H 1

#include <type_traits>
#include <iostream>
#include <unordered_map>
#include <unordered_set>
#include <vector>
#include <cassert>
#include <gsl/gsl>

std::string routingbits_string(std::map<uint32_t, std::string> map);

std::map<uint32_t, std::string> rb_map(std::string s);
#endif
