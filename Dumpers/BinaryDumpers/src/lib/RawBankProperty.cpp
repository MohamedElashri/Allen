/*****************************************************************************\
* (c) Copyright 2000-2021 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/

#include <GaudiKernel/ParsersFactory.h>
#include <GaudiKernel/GaudiException.h>
#include <Dumpers/RawBankProperty.h>

StatusCode LHCb::parse(RawBank::BankType& result, const std::string& in)
{
  static std::unordered_map<std::string, RawBank::BankType> types;
  if (types.empty()) {
    for (int t = 0; t < RawBank::LastType; ++t) {
      auto bt = static_cast<RawBank::BankType>(t);
      types.emplace(RawBank::typeName(bt), bt);
    }
  }

  // This takes care of quoting
  std::string input;
  using Gaudi::Parsers::parse;
  auto sc = parse(input, in);
  if (!sc) return sc;

  auto it = types.find(input);
  if (it != end(types)) {
    result = it->second;
    return StatusCode::SUCCESS;
  }
  else {
    return StatusCode::FAILURE;
  }
}

StatusCode LHCb::parse(std::unordered_set<RawBank::BankType>& s, const std::string& in)
{
  std::unordered_set<std::string> ss;
  using Gaudi::Parsers::parse;
  auto sc = parse(ss, in);
  if (!sc) return sc;
  s.clear();
  try {
    std::transform(begin(ss), end(ss), std::inserter(s, begin(s)), [](const std::string& s) {
      RawBank::BankType t {};
      auto sc = parse(t, s);
      if (!sc) throw GaudiException("Bad Parse", "", sc);
      return t;
    });
  } catch (const GaudiException& ge) {
    return ge.code();
  }
  return StatusCode::SUCCESS;
}

std::ostream& LHCb::toStream(const RawBank::BankType& bt, std::ostream& s)
{
  return s << "'" << RawBank::typeName(bt) << "'";
}
