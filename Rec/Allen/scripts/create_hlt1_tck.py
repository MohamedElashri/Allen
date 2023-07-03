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
import os
import argparse
import json
import sys
import subprocess
import logging
from PyConf.filecontent_metadata import flush_key_registry, retrieve_encoding_dictionary, metainfo_repos, ConfigurationError, FILE_CONTENT_METADATA
from Allen.tck import sequence_to_git, sequence_from_python
from pathlib import Path

logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)

parser = argparse.ArgumentParser(description="""
Persist an Allen configuration in a git repository identified by a TCK

The configuration can be obtained from:
- a JSON file
- a python module that generates a configuration
- a python file that generatea a configuration

Some metadata is also persisted.
""")
parser.add_argument("stack")
parser.add_argument("sequence")
parser.add_argument("repository")
parser.add_argument("tck", help="A 32-bit hexadecimal number")
parser.add_argument(
    "-t,--hlt1-type",
    type=str,
    help=
    "Sequence type to use; also used as branch name in the Git repository.",
    default='',
    dest='sequence_type')
parser.add_argument(
    "--python-hlt1-node",
    type=str,
    help=
    "Name of the variable that stores the configuration in the python module or file",
    default="hlt1_node",
    dest="hlt1_node",
)
parser.add_argument(
    "--label",
    help="Label persisted as metadata together with the TCK",
    default="test",
    type=str,
)

args = parser.parse_args()

sequence_arg = Path(args.sequence)
repository = Path(args.repository)
tck = int(args.tck, 16)
type_arg = args.sequence_type if args.sequence_type != '' else sequence_arg.stem

local_metainfo_repo = Path("./lhcb-metainfo/.git")
tck_metainfo_repos = [(str(local_metainfo_repo.resolve()), "master"),
                      (FILE_CONTENT_METADATA, "master")]

# Unset this environment variable to force generation of new encoding
# keys in a local repo if they are not in the cvmfs one
build_metainfo_repo = os.environ.pop('LHCbFileContentMetaDataRepo', None)
if build_metainfo_repo is not None and not local_metainfo_repo.exists():
    result = subprocess.run([
        'git', 'clone', '-q', build_metainfo_repo,
        str(local_metainfo_repo.resolve()).removesuffix('/.git')
    ],
                            capture_output=True,
                            text=True,
                            check=False)
    if result.returncode != 0:
        print(
            f"Failed to clone build metainfo repo {build_metainfo_repo} to local repo"
        )
        sys.exit(1)


def dec_reporter_name(conf):
    return next(
        (n for t, n, _ in conf["sequence"]["configured_algorithms"]
         if t == "dec_reporter::dec_reporter_t"),
        None,
    )


sequence = None
if sequence_arg.suffix in (".py", ""):
    from AllenCore.configuration_options import is_allen_standalone

    is_allen_standalone.global_bind(standalone=True)

    from AllenConf.persistency import make_dec_reporter

    sequence, dn = {}, None
    # Load the python module to get the sequence configuration; set
    # the TCK to the right value and flush encoding keys
    with (make_dec_reporter.bind(TCK=tck), flush_key_registry()):
        sequence = sequence_from_python(sequence_arg, node_name=args.hlt1_node)
        sequence = json.loads(json.dumps(sequence, sort_keys=True))

    # Check that at least the dec_reporter is part of the sequence,
    # otherwise it's meaningless to create a TCK for this sequence.
    dn = dec_reporter_name(sequence)
    if dn is None:
        print(
            f"Cannot create TCK {hex(tck)} for sequence {type_arg}, because it does not contain the dec_reporter"
        )
        sys.exit(1)
elif sequence_arg.suffix == ".json":
    # Load the sequence configuration from a JSON file
    sequence, dn = {}, None
    with open(sequence_arg, "r") as sequence_file:
        sequence = json.load(sequence_file)

    # Get the dec reporter and set its TCK property to the right value
    # before creating the TCK from the configuration
    dn = dec_reporter_name(sequence)
    if dn is None:
        print(
            f"Cannot create TCK {hex(tck)} for sequence {type_arg}, because it does not contain the dec_reporter"
        )
        sys.exit(1)
    else:
        sequence[dn]["tck"] = tck

# Store the configuration in the Git repository and tag it with the TCK
try:
    sequence_to_git(repository, sequence, type_arg, args.label, tck,
                    args.stack, {"settings": sequence_arg.stem}, True)
    print(f"Created TCK {hex(tck)} for sequence {type_arg}")
except RuntimeError as e:
    print(e)
    sys.exit(1)


def get_encoding_key(repo):
    try:
        with metainfo_repos.bind(repos=[(repo, "master")]):
            return retrieve_encoding_dictionary(
                reports_key, require_key_present=True)
    except ConfigurationError:
        return None


# Check that the encoding key is either in CVMFS or in the local
# metadata repository
reports_key = sequence[dn]["encoding_key"]

local_key, key_present = (False, False)
if local_metainfo_repo.exists():
    encoding = get_encoding_key(str(local_metainfo_repo.resolve()))
    key_present = local_key = encoding is not None
if not local_key:
    encoding = get_encoding_key(FILE_CONTENT_METADATA)
    key_present = encoding is not None

if not key_present:
    print("Key {} cannot be found!".format(hex(reports_key)))
    sys.exit(1)
