/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <map>
#include <string>
#include <sstream>
#include <optional>
#include <RoutingBits.h>
#include <Common.h>
#include <regex>

// std::map to string converter to parse routing bits as a property
std::string routingbits_string(std::map<uint32_t, std::string> map)
{
  std::string output = "";
  std::string convrt = "";
  std::string result = "";

  for (auto it = map.cbegin(); it != map.cend(); it++) {

    convrt = it->second;
    output += std::to_string(it->first) + ":" + (convrt) + ", ";
  }

  result = output.substr(0, output.size() - 2);
  return result;
}
// regex to concert python routing bit dictionary (routing bit: exression) to std::map
std::map<uint32_t, std::string> rb_map(std::string s)
{
  std::regex e("((?:\"[^\"]*\"|[^:{,])*): '((?:\"[^\"]*\"|[^,}])*)'");
  std::smatch m;
  std::map<uint32_t, std::string> rb;
  while (std::regex_search(s, m, e)) {
    rb[stoi(m[1])] = m[2];
    s = m.suffix().str();
  }

  return rb;
}
void from_json(const nlohmann::json& j,  std::map<uint32_t, std::string>& map)
{
  std::string s = j.get<std::string>();
  map = rb_map(s);
}

void to_json(nlohmann::json& j, const std::map<uint32_t, std::string>& map) { j = routingbits_string(map); }