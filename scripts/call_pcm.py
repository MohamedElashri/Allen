###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
import sys, os, time, signal
from subprocess import PIPE, Popen
from threading import Thread
import requests
from dateutil.parser import *
import datetime

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


def send_to_telegraf(tags, labels, values):
    full_date = "%s %s" % (values[0], values[1])
    date = datetime.datetime.strptime(full_date, "%Y-%m-%d %H:%M:%S")
    timestamp = date.timestamp() * 1000000000
    print('date =', date, ', timestamp = ', timestamp)

    indices = {5, 9, 10, 11, 12}
    for i in indices:
        tag = tags[i]
        label_raw = labels[i]
        val = values[i]

        # remove \n from last entry in list
        if i == 12:
            val = val[:-1]
            label_raw = label_raw[:-1]
            tag = tag[:-1]
        label = (label_raw.split("(")[0]).strip()

        telegraf_string = "AllenIntegrationTest,socket=%s " % (tag)
        telegraf_string += '{}={:.2f} '.format(label, float(val))
        telegraf_string += " %d" % timestamp

        send(telegraf_string)


def get_system_throughput(match_string):
    if match_string in string_line:
        split1 = string_line.split(":")
        split2 = split1[1].split("--|")
        return float(split2[0].strip())


def get_node_throughput(node):
    if 'NODE 0 Memory' in string_line:
        split1 = string_line.split("--||--")
        split2 = split1[node].split(":")
        if node == 1:
            return split2[1].split("--|")[0].strip()

        return float(split2[1].strip())


p = Popen(['./programs/pcm/pcm-memory.x', '-nc', '-csv', '5'],
          stdout=PIPE,
          bufsize=1,
          close_fds=ON_POSIX)

tags = []
labels = []
values = []
for stdout_line in iter(p.stdout.readline, b''):
    string_line = stdout_line.decode('utf-8')
    print(string_line)

    # if first line, get tags
    if 'SKT0' in string_line:
        tags = string_line.split(";")
    # if second line, get labels
    elif 'Date' in string_line:
        labels = string_line.split(";")
    else:
        values = string_line.split(";")
        print(values)

    if not values:
        continue

    send_to_telegraf(tags, labels, values)

os.killpg(os.getpgid(p.pid), signal.SIGTERM)
