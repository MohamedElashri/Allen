/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "BankTypes.h"
#include "Common.h"
#include "Property.cuh"
#include "Logger.h"

template<>
float Configuration::from_string<float>(const std::string& s)
{
  return atof(s.c_str());
}

template<>
double Configuration::from_string<double>(const std::string& s)
{
  return atof(s.c_str());
}

template<>
int Configuration::from_string<int>(const std::string& s)
{
  return strtol(s.c_str(), 0, 0);
}

template<>
unsigned Configuration::from_string<unsigned>(const std::string& s)
{
  return strtoul(s.c_str(), 0, 0);
}

template<>
BankTypes Configuration::from_string<BankTypes>(const std::string& s)
{
  auto bt = bank_type(s);
  if (bt == BankTypes::Unknown) {
    throw StrException {"Failed to parse " + s + " into a BankType."};
  }
  return bt;
}

// Specialization for DeviceDimensions
template<>
DeviceDimensions Configuration::from_string<DeviceDimensions>(const std::string& string_value)
{
  DeviceDimensions dimensions;
  std::smatch matches;
  auto r = std::regex_match(string_value, matches, Detail::array_expr);
  if (!r) {
    throw std::exception {};
  }
  auto digits_begin = std::sregex_iterator(string_value.begin(), string_value.end(), Detail::digit_expr);
  auto digits_end = std::sregex_iterator();
  if (std::distance(digits_begin, digits_end) != 3) {
    throw std::exception {};
  }
  int idx = 0;
  for (auto i = digits_begin; i != digits_end; ++i) {
    if (idx == 0) {
      dimensions.x = atoi(i->str().c_str());
    }
    else if (idx == 1) {
      dimensions.y = atoi(i->str().c_str());
    }
    else {
      dimensions.z = atoi(i->str().c_str());
    }
    idx++;
  }
  return dimensions;
}

template<>
std::string Configuration::to_string<DeviceDimensions>(const DeviceDimensions& holder)
{
  // very basic implementation based on streaming
  std::stringstream s;
  s << "[" << holder.x << ", " << holder.y << ", " << holder.z << "]";
  return s.str();
}

template<>
std::string Configuration::to_string<BankTypes>(const BankTypes& holder)
{
  return bank_name(holder);
}
