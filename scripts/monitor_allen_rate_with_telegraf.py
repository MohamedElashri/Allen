import sys, os, time, signal
from subprocess import PIPE, Popen
from threading  import Thread
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
 
    
def send_to_telegraf(rate, device):

    now = datetime.datetime.now()
    timestamp = datetime.datetime.timestamp(now) * 1000000000 
    
    telegraf_string = "AllenIntegrationTest,AllenInstance=%s " % (device)
    telegraf_string += "allen_rate=%.2f " % (float(rate)) 
    telegraf_string += " %d" % timestamp 
    
    send(telegraf_string)


def main():
    # if len(sys.argv) < 2:
    #     print('usage: allen_throughput.py <connect_to> <connect_to...>')
    #     sys.exit(1)
 

    ctx = zmq.Context()
    sockets = {}
    for f in ["0","1"]:
        con = "ipc:///tmp/allen_throughput_" + f
        print("connecting to: " + con)
        s = ctx.socket(zmq.SUB)
        s.connect(con)
        s.setsockopt(zmq.SUBSCRIBE, b'')
        sockets[s] = f.split('_')[-1]

    poller = zmq.Poller()
    for socket in sockets.keys():
        poller.register(socket, zmq.POLLIN)

    while True:
        polled = dict(poller.poll())
        for socket, device in sockets.items():
            if socket in polled and polled[socket] == zmq.POLLIN:
                message = socket.recv()
                print(device, message)
                send_to_telegraf(message, device)

if __name__ == "__main__":
    main()
 


 
