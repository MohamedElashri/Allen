###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
import sys
import os
import time
import signal
from subprocess import PIPE, Popen
from threading import Thread
import requests
from dateutil.parser import *
import datetime

import sys
import zmq

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


def send_to_telegraf(rate, device, app_name, rate_name):

    now = datetime.datetime.now()
    timestamp = datetime.datetime.timestamp(now) * 1000000000

    telegraf_string = "AllenIntegrationTest,%s=%s " % (app_name, device)
    telegraf_string += "%s=%.2f " % (rate_name, float(rate))
    telegraf_string += " %d" % timestamp

    send(telegraf_string)


def main():
    # if len(sys.argv) < 2:
    #     print('usage: allen_throughput.py <connect_to> <connect_to...>')
    #     sys.exit(1)

    ctx = zmq.Context()
    sockets = {}
    connections = {
        "ipc:///tmp/allen_throughput_%s": (["0", "1", "2"], 'AllenInstance',
                                           'allen_rate'),
        "tcp://%s:%s": ([('lbdaqrome02', '35001')], 'OutputWriter',
                        'output_rate')
    }
    for connection, (ids, app_name, rate_name) in connections.items():
        for socket_id in ids:
            if len(socket_id) > 1:
                con = connection % socket_id[:-1]
                app_id = socket_id[-1]
            else:
                con = connection % socket_id
                app_id = socket_id
            print("connecting to: " + con)
            s = ctx.socket(zmq.SUB)
            s.connect(con)
            s.setsockopt(zmq.SUBSCRIBE, b'')
            sockets[s] = (app_name, rate_name, app_id)

    poller = zmq.Poller()
    for socket in sockets.keys():
        poller.register(socket, zmq.POLLIN)

    while True:
        polled = dict(poller.poll())
        for socket, (app_name, rate_name, socket_id) in sockets.items():
            if socket in polled and polled[socket] == zmq.POLLIN:
                message = socket.recv()
                print(socket_id, message)
                send_to_telegraf(message, socket_id, app_name, rate_name)


if __name__ == "__main__":
    main()
