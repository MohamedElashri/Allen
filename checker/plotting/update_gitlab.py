###############################################################################
# (c) Copyright 2018-2021 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

import os
import gitlab

import argparse


parser = argparse.ArgumentParser(
    description="Update the current GitLab merge request with throughput CI results."
)

parser.add_argument(
    "--throughput-status",
    help="Add a hlt1-throughput-decreased label to the merge request.",
    choices=["decrease", "increase", "no-change", "nothing"],
    default="nothing",
)

args = parser.parse_args()


def get_merge_request():
    gl = gitlab.Gitlab(
        "https://gitlab.cern.ch", private_token=os.environ[f"ALLENCI_PAT"]
    )

    gl.auth()

    proj_id = int(os.environ["CI_PROJECT_ID"])
    project = gl.projects.get(proj_id)

    mr = project.mergerequests.get(int(os.environ["CI_MERGE_REQUEST_IID"]))

    return mr


def toggle_label(mr, name, enabled):
    if name in mr.labels and not enabled:
        mr.labels = list([l for l in mr.labels if l != name])
    elif enabled and name not in mr.labels:
        labels = mr.labels[:]
        labels += [name]
        mr.labels = list(set(labels))


def main():
    mr = get_merge_request()
    if args.throughput_status != "nothing":
        toggle_label(
            mr, "hlt1-throughput-decreased", args.throughput_status == "decrease"
        )
        # toggle_label(
        #     mr, "hlt1-throughput-increased", args.throughput_status == "increase"
        # )
        mr.save()


if __name__ == "__main__":
    main()
