#include "Configuration.cuh"
#include "Logger.h"

template<>
float Configuration::temp_from_string<float>(const std::string& s)
{
  return atof(s.c_str());
}

template<>
double Configuration::temp_from_string<double>(const std::string& s)
{
  return atof(s.c_str());
}

template<>
int Configuration::temp_from_string<int>(const std::string& s)
{
  return strtol(s.c_str(), 0, 0);
}

template<>
uint Configuration::temp_from_string<uint>(const std::string& s)
{
  return strtoul(s.c_str(), 0, 0);
}

// Specialization for double
template<>
bool Configuration::from_string<double>(double& holder, const std::string& value)
{
  holder = atof(value.c_str());
  return true;
}

// Specialization for float
template<>
bool Configuration::from_string<float>(float& holder, const std::string& value)
{
  holder = atof(value.c_str());
  return true;
}

// Specialization for uint
template<>
bool Configuration::from_string<uint>(uint& holder, const std::string& value)
{
  holder = strtoul(value.c_str(), 0, 0);
  return true;
}

// Specialization for int
template<>
bool Configuration::from_string<int>(int& holder, const std::string& value)
{
  holder = strtol(value.c_str(), 0, 0);
  return true;
}

template<>
std::string Configuration::to_string<std::array<uint, 3>>(std::array<uint, 3> const& holder)
{
  // very basic implementation based on streaming
  std::stringstream s;
  s << "[";
  bool first = true;
  for (auto v : holder) {
    if (first) {
      s << v;
      first = false;
    }
    else {
      s << ", " << v;
    }
  }
  s << "]";
  return s.str();
}

// function to define one float property as the inverse of another
template<>
float Configuration::Relations::inverse<float>(std::vector<Property<float>*> pars)
{
  if (pars.size() > 1) {
    warning_cout << "inverse relation will only use the first input Property" << std::endl;
  }

  if (pars.empty()) {
    warning_cout << "inverse relation requires an input Property" << std::endl;
    return 0.;
  }

  return 1.f / pars[0]->get_value();
}

/* Shared sets of properties may defined in classes that inherit from SharedPropertySet
 * To allow Algorithms to find the singleton, each such class must be included in Configuration::getSharedPropertySet
 * An example SharedPropertySet class (to be placed in its own header file) follows:
 *
 * #include "Configuration.cuh"
 *
 * namespace Configuration {
 *   namespace example_common {
 *     cuda_constant(float param)
 *   }
 * }
 *
 * struct ExampleConfiguration : public SharedPropertySet {
 *   ExampleConfiguration() = default;
 *   constexpr static auto name{ "example_common" };
 * private:
 *   Property<float> m_par{this, "param", Configuration::example_common::param, 0., "an example parameter"};
 * };
 *
 * This may be used by any algorithm by including the header and adding the following line
 * to the __VA_ARGS__ of the ALGORITHM call
 *
 * SharedProperty<float> m_shared{this, "example_common", "param"};
 *
 */
SharedPropertySet* Configuration::getSharedPropertySet(const std::string& name)
{
  static std::map<std::string, SharedPropertySet*> m_sets;

  if (m_sets.find(name) != m_sets.end()) {
    return m_sets.at(name);
  }

  // EXAMPLE SharedPropertySet integration
  // if(name==ExampleConfiguration::name) {
  //  auto r = m_sets.emplace(name, new ExampleConfiguration);
  //  if (std::get<1>(r)) return (*std::get<0>(r)).second;
  //}

  warning_cout << "Unknown shared property set " << name << std::endl;
  return nullptr;
}
