###############################################################################
# (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "COPYING".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
"""Utilities to create and retrieve Allen configurations from the
persistance format saved in a git repository.

The persistent format is organised as a collection of JSON files, with
each JSON file representing the configuration of a single
component. In the case of Allen the only components that exist are
algorithms.

Each JSON file is stored in the repository at a path that is formatted as:

"scope/namespace::type/instance_name",

where scope is the defined as part of the Allen configuration and may
be DeviceAlgorithm, HostAlgorithm, BarrierAlgorithm, ProviderAlgorithm
or SelectionAlgorithm. There is an additional "folder" under Scheduler
where the more-or-less free-form (but still in JSON files)
configuration of the scheduler/sequence is persisted.

The layout of the configuration of a single algorithm/component is for example for
"DeviceAlgorithm/velo_search_by_triplet::velo_search_by_triplet_t/velo_search_by_triplet":

{
    "Kind": "DeviceAlgorithm",
    "Name": "velo_search_by_triplet",
    "Properties": {
        "block_dim_x": "64",
        "max_scatter": "0.08",
        "max_skipped_modules": "1",
        "phi_tolerance": "0.045",
        "verbosity": "3"
    },
    "Type": "velo_search_by_triplet::velo_search_by_triplet_t"
}

It should be noted that the JSON type of all the values in
"Properties" are strings and not JSON types. This is a requirement of
the persistent format.

For Allen/HLT1 the Scheduler "folder" contains four files:
argument_dependencies, configured_algorithms, configured_arguments and
configured_sequence_arguments. These are the same as the entries that
an Allen-layout configuration expects under "sequence".

Some additional metadata is needed when a configuration is persisted, in particular e.g.:

{
   "Release2Type": {
        "ALLEN_v3r6": "hlt1_pp_only_matching"
    },
    "TCK": "0x10000016",
    "label": "test"
}

Each of these entries is stored with a "digest" as key, whose value is
not important, but is also used as a key for the corresponding
configuration when it is extracted from the git repository.

Some of the code that is needed to persist configurations is not
available as python bindings, but instead through the
"hlt_tck_tool" executable that resides in
LHCb/Hlt/HltServices. It is also needed to create a JSON manifest that
contains all configurations available in the repository.
"""

import json
import os
import sys
import re
import importlib
import importlib.util
from pathlib import Path
from lxml import etree
from hashlib import md5
from subprocess import PIPE, run


def format_tck(tck: int):
    return f"0x{tck:08X}"


def dependencies_from_build_manifest():
    """Get the built/installed version of Allen from the
    build/install manifest in the format ALLEN_vXrYpZ where pZ is
    optional.
    """

    if "ALLEN_INSTALL_DIR" in os.environ:
        manifest_tree = etree.parse(
            os.path.expandvars("${ALLEN_INSTALL_DIR}/manifest.xml"))
        projects = (
            [manifest_tree.find("project")] +
            [p for p in manifest_tree.find("used_projects").iterchildren()])
        deps = {p.get("name"): p.get("version") for p in projects}
        deps["LCG"] = manifest_tree.find("heptools").find("version").text
        return deps
    else:
        return {}


def sequence_to_tck(config: dict):
    """Convert an "Allen" configuration to the format required for
    persistence. This includes in particular the (JSON) serialization
    of all property values to strings.
    """

    tck_config = {"Scheduler/" + k: v for k, v in config["sequence"].items()}

    for alg_type, alg_name, alg_kind in config["sequence"][
            "configured_algorithms"]:
        properties = {
            k: v if type(v) == str else json.dumps(v)
            for k, v in config[alg_name].items()
        }
        tck_config[f"{alg_kind}/{alg_type}/{alg_name}"] = {
            "Name": alg_name,
            "Kind": alg_kind,
            "Type": alg_type,
            "Properties": properties,
        }

    return tck_config


def tck_to_sequence(config: dict):
    """Convert a persisted configuration to an "Allen" configuration.
    """

    scheduler_entries = [
        k.split("/")[1] for k in config.keys() if k.startswith("Scheduler/")
    ]
    sequence_config = {
        "sequence": {e: config["Scheduler/" + e]
                     for e in scheduler_entries}
    }

    for alg_type, alg_name, alg_kind in sequence_config["sequence"][
            "configured_algorithms"]:
        tck_props = config[f"{alg_kind}/{alg_type}/{alg_name}"]["Properties"]
        properties = {}
        for k, v in tck_props.items():
            try:
                properties[k] = json.loads(v)
            except json.JSONDecodeError:
                properties[k] = v
        sequence_config[alg_name] = properties

    return sequence_config


def json_tck_db(configuration: dict, sequence_type: str, metadata: dict,
                tck: int):
    """Create a JSON-formatted string that hlt_tck_tool can
    write to a git repository.

    The hlt_tck_tool resides in LHCb/Hlt/HltServices. It is passed a
    JSON-formatted string through stdin. The JSON contains two
    entries: a single-entry manifest with the key "manifest" and the
    respective configuration with its digest as key. The same digest
    is used as the key for the entry containing the metadata in the
    manifest.

    """
    if len(hex(tck)) != 10 or hex(tck)[2] != "1":
        raise ValueError(
            "Badly formatted TCK, it must be a 32 bit hex number with most significant byte set to 1"
        )

    # Add the configuration to the TCK
    tck_config = sequence_to_tck(configuration)

    # The value of the digest is not important as long as it matches
    # between the manifest and the key of the configuration. Use MD5
    # as that was used extensively and more meaningfully in Run 2.
    # The digest is calculated without including metadata.json
    # (which contains the digest itself!)
    digest = md5(json.dumps(tck_config).encode("utf-8")).hexdigest()
    metadata = metadata.copy()
    metadata["digest"] = digest

    # Add the metadata to the TCK in a file called "metadata.json"
    # This is a name we can "never" change!
    tck_config['metadata.json'] = metadata

    manifest = {
        # FIXME the digest, TCK and branch are redundant, they're all in metadata
        digest: {
            "TCK": hex(tck),
            "branch": sequence_type,
            "metadata": metadata
        }
    }
    return {"manifest": manifest, digest: tck_config}


def sequence_from_python(python_file: Path, node_name="hlt1_node") -> dict:
    """Retrieve an Allen configuration in JSON format from a python module
    """

    from AllenCore.allen_standalone_generator import generate, build_sequence
    from AllenCore.AllenSequenceGenerator import generate_json_configuration

    module_name = python_file.stem

    node = None
    with generate.bind(noop=True):
        if python_file.suffix == "":
            # Load sequence module from installed sequence
            mod = importlib.import_module(f"AllenSequences.{module_name}")
        else:
            # Load sequence module from python file
            spec = importlib.util.spec_from_file_location(
                module_name, python_file)
            mod = importlib.util.module_from_spec(spec)
            sys.modules[module_name] = mod
            spec.loader.exec_module(mod)

        node = getattr(mod, node_name)

    if node is None:
        print(
            f"Failed to get {node_name} from sequence file {str(python_file)}")
        return None

    algorithms = build_sequence(node, verbose=False)
    return generate_json_configuration(algorithms)


def sequence_to_git(
        repository: Path,
        sequence: dict,
        sequence_type: str,
        label: str,
        tck: int,
        stack: str,
        extra_metadata={},
        write_intermediate=False,
):
    """Write an Allen configuration to a git repository with metadata.
    """
    from Allen import TCK

    if not re.match(r"^0x1[0-9A-F]{7}$", format_tck(tck)):
        raise ValueError(
            f"TCK {format_tck(tck)} does not match 0x1XXXXXXX pattern")

    # Collect metadata for TCK
    metadata = extra_metadata.copy()
    metadata["version"] = 1  # updating this must be synchronised with TCKUtils
    metadata["TCK"] = format_tck(tck)
    metadata["config_version"] = ["Allen", TCK.config_version]
    metadata[
        "application"] = "Hlt1"  # match the "SourceID" or the "process/stage"
    metadata["label"] = label
    metadata["type"] = sequence_type
    metadata["stack"] = {
        "name": stack,
        "projects": dependencies_from_build_manifest()
    }

    # Craete JSON TCK DB
    db = json_tck_db(sequence, sequence_type, metadata, tck)
    if write_intermediate:
        with open(hex(tck) + ".json", "w") as f:
            json.dump(db, f, indent=4, sort_keys=True)

    p = run(
        ["hlt_tck_tool", "--convert-to-git", "-", f"{str(repository)}"],
        stdout=PIPE,
        stderr=PIPE,
        input=json.dumps(db, indent=4, sort_keys=True),
        encoding="ascii",
    )

    if p.returncode != 0:
        print(p.stdout)
        print(p.stderr)
        raise RuntimeError("Failed to convert sequence to git repo")


def sequence_from_git(repository: Path, tck: str, use_bindings=True) -> str:
    """Retrieve the Allen configuration identified by the given TCK
    from a git repository.

    use_bindings determines wether a Python module (default) or
    hlt_tck_tool is used to retrieve the JSON configuration.
    """

    if use_bindings:
        from Allen import TCK
        sequence, info = TCK.sequence_from_git(str(repository), tck)
        tck_info = {
            k: getattr(info, k)
            for k in ("digest", "tck", "release", "type", "label")
        }
        tck_info["metadata"] = json.loads(info.metadata)
        return (sequence, tck_info)
    else:
        p = run(
            [
                "hlt_tck_tool",
                f"--tck={tck}",
                "--convert-to-json",
                f"{str(repository)}",
                "-",
            ],
            stdout=PIPE,
        )
        if p.returncode != 0:
            print("Failed to convert configuration in git repo to JSON")
            return None
        tck_db = json.loads(p.stdout)
        digest, manifest_entry = next(
            ((k, m) for k, m in tck_db["manifest"].items() if m["TCK"] == tck),
            None)
        release, seq_type = next(
            (k, v) for k, v in manifest_entry["Release2Type"].items())
        tck = manifest_entry["TCK"]
        label = manifest_entry["label"]
        metadata = manifest_entry["metadata"]
        info = {
            "digest": digest,
            "tck": tck,
            "metadata": metadata,
            "type": seq_type,
            "label": label,
            "metadata": metadata
        }
        return (json.dumps(tck_to_sequence(tck_db[digest])), info)


def property_from_git(repository: Path,
                      tck: str,
                      algorithm=".*",
                      property=".*"):
    alg_re = re.compile(algorithm)
    prop_re = re.compile(property)
    """Retrieve an Allen configuration identified by TCK from a git
    repository and extract specific properties from it using regexes
    to match algorithm name and property key
    """

    s, _ = sequence_from_git(repository, tck)
    sequence = json.loads(s)

    result = {}
    for alg, props in sequence.items():
        if alg == "scheduler" or not alg_re.match(alg):
            continue
        prop_result = {k: v for k, v in props.items() if prop_re.match(k)}
        if prop_result:
            result[alg] = prop_result

    return result


def manifest_from_git(repository: Path):
    """Use hlt_tck_tool to retrieve the manifest for a git
    repositry
    """

    args = [
        "hlt_tck_tool", "--list-manifest-as-json", f"{str(repository)}", "-"
    ]
    p = run(args, stdout=PIPE, stderr=PIPE)
    if p.returncode != 0:
        print("Failed to convert manifest from git repo to JSON")
        print(p.stdout)
        print(p.stderr)
        return None
    else:
        return json.loads(p.stdout)
