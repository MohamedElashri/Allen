import sys
import os
import time
import pprint
import signal
import re
from subprocess import PIPE, STDOUT, Popen
from threading import Thread
import datetime
import requests
import traceback
from collections import defaultdict

ON_POSIX = 'posix' in sys.builtin_module_names


def send(telegraf_string):
    telegraf_url = 'http://localhost:8186/telegraf'
    session = requests.session()
    session.trust_env = False
    try:
        print('Sending telegraf string: %s' % telegraf_string)
        response = session.post(telegraf_url, data=telegraf_string)
        print('http response: %s' % response.headers)
    except:
        print('Failed to submit data string %s' % telegraf_string)
        print(traceback.format_exc())


def send_to_telegraf(rates):

    now = datetime.datetime.now()
    timestamp = datetime.datetime.timestamp(now) * 1000000000
    print('timestamp = ', timestamp)

    for interface, rate in rates.items():
        telegraf_string = "AllenIntegrationTest,pcie40_interface=%s " % interface
        telegraf_string += "rate=%.2f " % rate
        telegraf_string += " %d" % timestamp

        print(telegraf_string)

        send(telegraf_string)


pcie40_id = Popen(['pcie40_id'],
                  stdout=PIPE,
                  stderr=STDOUT,
                  close_fds=ON_POSIX)
o, e = pcie40_id.communicate()

interface_expr = re.compile(r"Interface: (\d+)")
rate_expr = re.compile(r"(\d+): (\d+\.\d+) Gbps, (\d+\.\d+) Gbps")
interfaces = []
for line in o.decode().split('\n'):
    line = line.strip()
    m = interface_expr.match(line)
    if m:
        interfaces.append(int(m.group(1)))

with Popen(['unbuffer', 'pcie40_daq', '-rfegO'],
           bufsize=1,
           universal_newlines=True,
           stdout=PIPE,
           stderr=STDOUT) as pcie40_daq:
    rates = defaultdict(list)
    n = 0
    for line in pcie40_daq.stdout:
        line = line.strip()
        m = rate_expr.match(line)
        rates[int(m.group(1))].append(float(m.group(2)))
        n += 1
        if n == 10 * len(interfaces):
            av_rates = {k: sum(v) / len(v) for k, v in rates.items()}
            send_to_telegraf(av_rates)
            rates = defaultdict(list)
            n = 0

os.killpg(os.getpgid(pcie40_daq.pid), signal.SIGTERM)
