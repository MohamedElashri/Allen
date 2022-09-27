###############################################################################
# (c) Copyright 2018-2022 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
#!/usr/bin/env python

import time
import yaml
import argparse
import logging
import re
import logging
import colorlog
from tabulate import tabulate
from shutil import copyfile
from sys import exit
from os import environ
from itertools import groupby, product
from pathlib import Path
from subprocess import CalledProcessError, TimeoutExpired, check_output


PASS = 1000
logging.addLevelName(PASS, "PASS")

FAIL = 1001
logging.addLevelName(FAIL, "FAIL")

log = colorlog.getLogger("AllenCI")
log.setLevel("DEBUG")


def log_pass(msg, *args, **kwargs):
    if log.isEnabledFor(PASS):
        log._log(PASS, msg, args, **kwargs)


def log_fail(msg, *args, **kwargs):
    if log.isEnabledFor(FAIL):
        log._log(FAIL, msg, args, **kwargs)


handler = colorlog.StreamHandler()
handler.setFormatter(
    colorlog.ColoredFormatter(
        "%(name)-10s%(log_color)s%(levelname)-8s%(reset)s %(message)s",
        datefmt=None,
        reset=True,
        log_colors={
            "DEBUG": "cyan",
            "INFO": "green",
            "PASS": "black,bg_green",
            "FAIL": "red,bg_white",
            "WARNING": "yellow",
            "ERROR": "white,bg_red",
            "CRITICAL": "red,bg_white",
        },
        secondary_log_colors={},
        style="%",
    )
)

handler.setLevel("INFO")
log.addHandler(handler)

fh = logging.FileHandler("AllenCI_full.log", mode="w")
fh.setLevel(logging.DEBUG)
fh.setFormatter(logging.Formatter("%(asctime)s:%(name)s:%(levelname)s:%(message)s"))
log.addHandler(fh)

device_id = environ["DEVICE_ID"]
lcg_system = environ["LCG_SYSTEM"]
lcg_qual = environ["LCG_QUALIFIER"]
ci_sha = environ["CI_COMMIT_SHORT_SHA"]
target = None

if "cpu" in lcg_qual:
    target = "CPU"
elif "cuda" in lcg_qual:
    target = "CUDA"
elif "hip" in lcg_qual:
    target = "HIP"
else:
    raise EnvironmentError(
        "LCG_QUALIFIER does not contain cpu, hip, or cuda. Cannot determine target."
    )

log.info(
    "Environment variables used: "
    + "; ".join(
        [
            f'{x}="{environ[x]}"'
            for x in [
                "DEVICE_ID",
                "LCG_SYSTEM",
                "LCG_QUALIFIER",
                "CI_COMMIT_SHORT_SHA",
            ]
        ]
    )
)


def expand_dict(data: dict):
    data = {k: [v] if not isinstance(v, list) else v for k, v in data.items()}
    grouped = [a for a, b in data.items() if isinstance(b, list)]
    p = [
        [a, list(b)]
        for a, b in groupby(product(*[data[i] for i in grouped]), key=lambda x: x[0])
    ]
    return [tuple({**data, **dict(zip(grouped, i))} for i in c) for _, c in p]


def read_test_configuration(filename: Path):
    with open(filename, "r") as f:
        return yaml.safe_load(f)


def write_text(filename: Path, text: str):
    filename.write_text(text)
    log.debug(f"Written {filename}.")


def post_proc_throughput(
    test, log_output, run_profiler_output: Path = None, allen_profiler_log: str = None
):
    build_options = test.get("build_options", "")
    output_directory = Path(
        f"run_throughput_output_{test['sequence']}_{test['dataset']}{build_options}/{device_id}"
    )
    output_directory.mkdir(parents=True, exist_ok=False)

    # look for throughput measure
    throughput_srch = re.search(
        r"^([0-9\.]+)\s+events\/s$", log_output, flags=re.MULTILINE
    )
    full_device_name_srch = re.search(
        r"^\s+select device to use \(--device\): .*?, ([A-Za-z0-9\-\s]+)$",
        log_output,
        flags=re.MULTILINE,
    )

    if not throughput_srch:
        return
    throughput = throughput_srch.group(1)

    full_device_name = device_id
    if full_device_name_srch:
        full_device_name = full_device_name_srch.group(1)

    write_text(output_directory / "input_files.txt", test["dataset"])
    write_text(output_directory / "sequence.txt", test["sequence"])
    write_text(output_directory / "revision.txt", ci_sha)
    write_text(output_directory / "buildopts.txt", build_options)
    write_text(output_directory / "throughput.txt", throughput)
    write_text(output_directory / "output.txt", log_output)
    log.info(f"Test log file can be found at {output_directory}/output.txt.")

    # if "TPUT_REPORT" in environ and environ["TPUT_REPORT"] == "NO_REPORT":
    if "throughput_report" in test and test["throughput_report"] == False:
        log.info("No throughput report will be written for this test.")
        write_text(output_directory / "no_throughput_report.txt", "No report please")

    log.debug(
        f"Device {full_device_name} has throughput {float(throughput)*1e-3:.2f} kHz"
    )

    if run_profiler_output and run_profiler_output.exists():
        profiler_keep_files = [
            "algo_breakdown.csv",
            "allen_report.csv",
            "allen_report_custom_metric.csv",
            "allen_report.ncu-rep",
        ]
        for fn in profiler_keep_files:
            copyfile(
                run_profiler_output / fn,
                output_directory / fn,
            )
        write_text(output_directory / "profiler_output.log", allen_profiler_log)
        log.info(
            f"Profiler log file can be found at {output_directory}/profiler_output.log."
        )

        log.debug("Copied profiler outputs to output directory successfully.")

    return {"throughput": float(throughput), "device": full_device_name}


def post_proc_efficiency(
    test: dict,
    log_output: str,
    run_profiler_output: Path = None,
    allen_profiler_log: str = None,
):
    build_options = test.get("build_options", "")
    output_directory = Path(
        f"run_physics_efficiency_output_{test['sequence']}{build_options}"
    )
    output_directory.mkdir(parents=True, exist_ok=True)
    write_text(
        output_directory / f"{test['dataset']}_{test['sequence']}_{device_id}.txt",
        log_output,
    )

    return {}


def post_proc_run_changes(
    test: dict,
    log_output: str,
    run_profiler_output: Path = None,
    allen_profiler_log: str = None,
):
    disable_run_changes = int(test["disable_run_changes"])
    output_directory = None
    if disable_run_changes == 1:
        output_directory = Path(f"run_no_run_changes_output_{test['sequence']}")
    elif disable_run_changes == 0:
        output_directory = Path(f"run_with_run_changes_output_{test['sequence']}")
    else:
        raise ValueError("disable_run_changes must be 0 or 1.")
    output_directory.mkdir(parents=True, exist_ok=True)
    write_text(output_directory / f"minbias_{device_id}.txt", log_output)

    return {}


def post_proc_run_built_tests(
    test: dict,
    log_output: str,
    run_profiler_output: Path = None,
    allen_profiler_log: str = None,
):
    log.debug("run_built_tests finished with output\n" + log_output)

    return {}


test_postproc = {
    "throughput": post_proc_throughput,
    "efficiency": post_proc_efficiency,
    "run_changes": post_proc_run_changes,
    "run_built_tests": post_proc_run_built_tests,
}


def run_allen_test(wrapper: str, test: dict, config: dict):
    test_name = test["type"]
    profile_device = config["profile_device"]

    log.info(f"Start test {test_name} {test!r}")

    args = build_allen_args(config, test, target)
    env_prefix = build_allen_env(config, test, target)

    allen = f"{env_prefix} ./{wrapper} {args} 2>&1".strip()

    timeout = test.get("timeout", config.get("default_timeout", 20 * 60))
    log.info(f"Configured timeout {timeout} sec")

    log.info(f"Starting Allen with: {allen}")
    allen_log = "None"
    try:
        start = time.time()
        allen_log = check_output(allen, shell=True, text=True, timeout=timeout)
        elapsed = time.time() - start
        log.debug("Log output:\n" + allen_log)
        log.info(f"Allen process completed in {elapsed:.2f} sec")

        allen_profiler_log = None
        profile_output_dir = None

        # Only run for throughput tests, and for a specific device.
        if profile_device == device_id and test_name == "throughput":
            # create a directory for the profiler output to go
            profile_output_dir = Path(f"run_profiler_{device_id}_{int(time.time())}")
            profile_output_dir.mkdir(exist_ok=False)

            # build profiler command
            profiler_args = build_allen_args(config, test, f"{target}PROF")
            profiler_env_prefix = build_allen_env(
                config,
                test,
                f"{target}PROF",
                RUN_PROFILER_OUTPUT=profile_output_dir.as_posix(),
            )
            allen_profiler = (
                f"{profiler_env_prefix} ./{wrapper} {profiler_args} 2>&1"
            ).strip()

            log.info(f"Running profiler with: {allen_profiler}")
            start = time.time()
            allen_profiler_log = check_output(
                allen_profiler, shell=True, text=True, timeout=timeout
            )
            elapsed = time.time() - start
            log.debug("Log output:\n" + allen_profiler_log)
            log.info(f"Allen profiling completed in {elapsed:.2f} sec")

    except CalledProcessError as e:
        log.error("\n" + e.output)
        log.exception(e)
        log_fail(
            f"Error during {test_name} test {test!r}. See above for output and traceback."
        )
        return False
    except TimeoutExpired as e:
        log.error("\n" + e.output)
        log.exception(e)
        log_fail(
            f"TIMEOUT {timeout} sec expired during {test_name} test {test!r}. See above for output."
        )
        return False

    postproc = None
    if test_name in test_postproc:
        log.info(f"Run postprocessing for test {test_name}")

        postproc = test_postproc[test_name](
            test,
            allen_log,
            allen_profiler_log=allen_profiler_log,
            run_profiler_output=profile_output_dir,
        )
        log.debug(f"Postprocessing returned {postproc!r}")

    log_pass(f"Finished {test_name} test {test!r}")
    return postproc or allen_log


def build_allen_args(config, test, target):
    args_cfg = config["args"]

    if test["type"] == "run_built_tests":
        return ""

    args = [args_cfg["base"]]
    for key, value in test.items():
        if key in args_cfg:
            args.append(args_cfg[key].format(**{key: value}))

    # now add args by test type
    test_args_cfg = config["test_args"]
    if test["type"] in test_args_cfg:
        args.append(test_args_cfg[test["type"]])

    # now add args by device target
    target_args_cfg = config["target_args"]
    if test["type"] in target_args_cfg and target in target_args_cfg[test["type"]]:
        args.append(target_args_cfg[test["type"]][target])

    return " ".join(args)


def build_allen_env(config, test, target, **env_args):
    test_name = test["type"]

    result = {**env_args}
    result["OPTIONS"] = test.get("build_options", None)
    result["LCG_OPTIMIZATION"] = test.get("lcg_opt", None)

    if test_name == "run_built_tests":
        result["RUN_UNIT_TESTS"] = "1"
        result["JUNITREPORT"] = f"default-{lcg_system}-unit-tests.xml"

    if target.endswith("PROF"):
        result["RUN_PROFILER"] = "1"
        assert "RUN_PROFILER_OUTPUT" in env_args, f"RUN_PROFILER_OUTPUT must be set for {target} target"

    return " ".join([f'{k}="{v}"' for k, v in result.items() if v is not None])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--allen-wrapper", required=True, type=str)
    parser.add_argument("--test-group", required=True, type=str)
    parser.add_argument("--test-config", required=True, type=Path)

    # parser.add_argument("--device-id", required=True, type=str)
    # parser.add_argument("--lcg-qualifier", required=True, type=str)
    # parser.add_argument("--build-options", required=True, type=str)

    args = parser.parse_args()

    log.info("Welcome to AllenCI")
    log.debug("(welcome to AllenCI)")

    config = read_test_configuration(args.test_config)

    if not args.test_group in config or args.test_group == "config":
        raise ValueError(
            f"No key (test group) {args.test_group} found in config file {args.test_config}"
        )

    test_group = config[args.test_group]

    total = 0
    skip = []
    ok = []
    bad = []

    execable_tests = []

    log.info("Figuring out which tests to run...")
    for testdef in test_group:
        for expanded_tests in expand_dict(testdef):
            for test in expanded_tests:
                assert "type" in test, f"Test instance {test!r} has no type defined!"
                if "allowed_devices" in test:
                    if test["allowed_devices"] != device_id:
                        log.info(
                            f"-- Skipping test {test!r} for this device {device_id} (!= {test['allowed_devices']})"
                        )
                        skip += [test]
                        continue
                execable_tests += [test]
                log.info(f"- {test!r}")

    def summarise_tests(tests):
        table_hdr = ["type"] + list(
            {
                t_key
                for t in tests
                for t_key in t.keys()
                if t_key
                not in ["timeout", "allowed_devices", "type", "throughput_report"]
            }
        )

        table = [[t[k] if k in t else "--" for k in table_hdr] for t in tests]

        log.info("\n" + tabulate(table, headers=table_hdr))

    total = len(execable_tests)
    summarise_tests(execable_tests)

    for i, test in enumerate(execable_tests):
        log.info(f"--- Test {i} of {total} ({i/total*100.0:.1f} % done) ---")
        if run_allen_test(args.allen_wrapper, test, config["config"]):
            ok += [test]
        else:
            bad += [test]

    table_hdr = ["type"] + list(
        {
            badtest_key
            for badtest in bad + ok + skip
            for badtest_key in badtest.keys()
            if badtest_key
            not in ["timeout", "allowed_devices", "type", "throughput_report"]
        }
    )

    table = (
        [
            ["FAIL"] + [badtest[k] if k in badtest else "--" for k in table_hdr]
            for badtest in bad
        ]
        + [
            ["pass"] + [test[k] if k in test else "--" for k in table_hdr]
            for test in ok
        ]
        + [
            ["skip"] + [test[k] if k in test else "--" for k in table_hdr]
            for test in skip
        ]
    )

    log.info("\n" + tabulate(table, headers=["result"] + table_hdr))

    log.info(
        f"{len(ok)} / {total} tests passed ({len(skip)} skipped), and "
        f"{len(bad)} failed. See AllenCI_full.log for full logging output."
    )
    if len(bad) > 0:
        log.error("Some tests failed! See above for log output.")

    return 0 if len(bad) == 0 else 1


if __name__ == "__main__":
    exit(main())
