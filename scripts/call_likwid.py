import sys, os, time, signal
from subprocess import PIPE, Popen, call
from threading import Thread
import datetime
import requests

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


def send_to_telegraf(labels, values):

    now = datetime.datetime.now()
    timestamp = datetime.datetime.timestamp(now) * 1000000000
    print('timestamp = ', timestamp)

    indices = {0, 1, 2}
    for i in indices:
        label = labels[i]
        val = values[i]

        telegraf_string = "AllenIntegrationTest,memory_bandwidth=%s " % 0
        telegraf_string += "%s=%.2f " % (label, float(val))
        telegraf_string += " %d" % timestamp

        print(telegraf_string)

        send(telegraf_string)


p = Popen([
    'sudo', '/usr/local/bin/likwid-perfctr', '-f', '-c', '0', '-g', 'MEM_eb',
    '-t', '2s'
],
          stdout=PIPE,
          stderr=PIPE,
          bufsize=1,
          close_fds=ON_POSIX)

rate_names = ['memory_read', 'memory_write', 'memory_total']

for stdout_line in iter(p.stderr.readline, b''):
    #print(stdout_line)
    string_line = stdout_line.decode()
    #print(string_line)

    # get rates
    values = []
    if not 'Sleeping' in string_line:
        line_values = string_line.split()
        values.append(line_values[5])
        values.append(line_values[6])
        values.append(line_values[7])
        print(values)

    if not values:
        continue

    send_to_telegraf(rate_names, values)

os.killpg(os.getpgid(p.pid), signal.SIGTERM)
