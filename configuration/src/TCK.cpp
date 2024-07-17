/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <dlfcn.h>

#include <boost/algorithm/string/classification.hpp>
#include <boost/algorithm/string/predicate.hpp>
#include <boost/algorithm/string/split.hpp>
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/xml_parser.hpp>
#include <boost/property_tree/detail/file_parser_error.hpp>
#include <FileSystem.h>

#include <git2.h>
#include <string>
#include <nlohmann/json.hpp>

#include <HltServices/TCKUtils.h>
#include <TCK.h>

// Version headers of dependent projects

namespace {
  namespace pt = boost::property_tree;
}

std::map<std::string, std::string> Allen::TCK::project_dependencies()
{
  Dl_info dl_info;
  if (!dladdr(reinterpret_cast<void*>(Allen::TCK::create_git_repository), &dl_info)) {
    throw std::runtime_error {"Failed to obtain path for this shared library"};
  }
  auto manifest_path = fs::absolute(fs::path {dl_info.dli_fname}.parent_path() / ".." / "manifest.xml");

  // Create an empty property tree object
  pt::ptree manifest;

  try {
    read_xml(manifest_path.string(), manifest);
  } catch (pt::xml_parser_error& e) {
    std::cout << "Failed to parse the xml string." << e.what();
  } catch (...) {
    std::cout << "Failed !!!";
  }

  std::map<std::string, std::string> deps;

  auto add_project_dep = [&deps](auto const& project) {
    deps[project.template get<std::string>("<xmlattr>.name")] = project.template get<std::string>("<xmlattr>.version");
  };

  deps["LCG"] = manifest.get<std::string>("manifest.heptools.version");
  for (auto& [_, project] : manifest.get_child("manifest.used_projects")) {
    add_project_dep(project);
  }
  add_project_dep(manifest.get_child("manifest.project"));
  return deps;
}

std::tuple<bool, std::string> Allen::TCK::check_projects(nlohmann::json metadata)
{
  auto projects_str = [](auto const& projects) {
    std::stringstream ps;
    for (auto [p, v] : projects) {
      ps << p << " " << v << "\n";
    }
    return ps.str();
  };

  auto projects = metadata.at("stack").at("projects").get<std::map<std::string, std::string>>();
  auto deps = Allen::TCK::project_dependencies();

  auto check = projects == deps;
  std::string error_msg;
  if (!check) {
    error_msg =
      ("dependencies " + projects_str(deps) + " are incompatible with current dependencies " + projects_str(projects));
  }
  return std::tuple {check, error_msg};
}

void Allen::TCK::create_git_repository(std::string repo_name)
{
  git_libgit2_init();

  auto [repo, sig] = LHCb::TCK::Git::create_git_repository(repo_name);

  git_signature_free(sig);
  git_repository_free(repo);
  git_libgit2_shutdown();
}

std::tuple<std::string, LHCb::TCK::Info> Allen::tck_from_git(std::string repo, std::string tck)
{

  using LHCb::TCK::Git::check;

  git_libgit2_init();
  git_repository* git_repo = nullptr;
  check(git_repository_open_bare(&git_repo, repo.c_str()));
  try {
    auto tck_config = LHCb::TCK::Git::extract_json(git_repo, tck);
    auto tck_info = LHCb::TCK::Git::tck_info(git_repo, tck);
    git_libgit2_shutdown();
    return {std::move(tck_config), std::move(tck_info)};
  } catch (std::runtime_error const& e) {
    git_libgit2_shutdown();
    throw std::runtime_error {"Failed to extract JSON configuration for TCK " + tck + " from " + repo + ": " +
                              e.what()};
  }
}

std::tuple<std::string, LHCb::TCK::Info> Allen::sequence_from_git(std::string repo, std::string tck)
{

  auto [tck_config, tck_info] = tck_from_git(repo, tck);
  if (tck_config.empty()) {
    return {tck_config, {}};
  }

  auto tck_db = nlohmann::json::parse(tck_config);
  nlohmann::json manifest = tck_db["manifest"];

  // The configuration JSON has a digest as key. Look at the
  // "manifest" part to find the digest. The manifests are also
  // indexed by digest, so loop over them until the one is found that
  // has the right TCK entry.
  auto items = tck_db.items();
  auto json_tck = std::find_if(items.begin(), items.end(), [&manifest, tck](auto const& e) {
    return e.key() != "manifest" && manifest.count(e.key()) && manifest[e.key()]["TCK"] == tck;
  });

  nlohmann::json sequence;

  std::vector<std::string> tokens;

  for (auto const& [entry, config] : json_tck.value().items()) {
    tokens.clear();
    boost::algorithm::split(tokens, entry, boost::algorithm::is_any_of("/"));
    if (tokens[0] == "Scheduler") {
      // Put special "sequence" items where they are expected
      sequence["sequence"][tokens[1]] = config;
    }
    else if (tokens.size() == 3) {
      // The rest is algorithm configuration. In the TCK all property
      // values are stored as strings, but Allen expects parsed JSON,
      // so convert between the two representations here. Some
      // properties are strings and won't parse, so we have to check
      // that.
      auto props = config["Properties"];
      nlohmann::json sequence_props;

      for (auto const& [prop_key, prop_val] : props.items()) {
        auto s = prop_val.get<std::string>();
        // Disable exceptions when parsing and test is_discarded to
        // check if the json is valid. If it's not valid, store as a
        // string
        auto j = nlohmann::json::parse(s, nullptr, false);
        if (j.is_discarded()) {
          sequence_props[prop_key] = s;
        }
        else {
          sequence_props[prop_key] = j;
        }
      }

      std::string const& alg_name = tokens[2];
      sequence[alg_name] = sequence_props;
    }
  }

  return {sequence.dump(), tck_info};
}
