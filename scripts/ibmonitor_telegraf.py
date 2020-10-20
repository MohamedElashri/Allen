#!/usr/bin/python3
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

from argparse import ArgumentParser
from itertools import starmap
import os
import sys
import time
import datetime
import requests

SYS_DIR = '/sys/class/infiniband'


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
 
    
def send_to_telegraf(labels, mbps_in_, mbps_out_, kpps_in_, kpps_out_):
    
    now = datetime.datetime.now()
    timestamp = datetime.datetime.timestamp(now) * 1000000000 
    print('Current Timestamp : ', timestamp)

    for lab, mbps_in, mbps_out, kpps_in, kpps_out in zip(labels, mbps_in_, mbps_out_, kpps_in_, kpps_out_):
        print(lab, mbps_in)
  
        telegraf_string = "AllenIntegrationTest,ib_link=%s " % (lab)
        telegraf_string += "mbps_in=%.2f,mbps_out=%.2f,kpps_in=%.2f,kpps_out=%.2f " % (float(mbps_in), float(mbps_out), float(kpps_in), float(kpps_out)) 
        telegraf_string += " %d" % timestamp 

        send(telegraf_string)
   

class Link(object):

    def __init__(self, hca, port):
        self.hca = hca
        self.port = port
        counters_dir = f'{SYS_DIR}/{hca}/ports/{port}/counters'
        self.dwords_in_file = open(f'{counters_dir}/port_rcv_data')
        self.dwords_out_file = open(f'{counters_dir}/port_xmit_data')
        self.packets_in_file = open(f'{counters_dir}/port_rcv_packets')
        self.packets_out_file = open(f'{counters_dir}/port_xmit_packets')

    def __del__(self):
        self.dwords_in_file.close()
        self.dwords_out_file.close()
        self.packets_in_file.close()
        self.packets_out_file.close()

    def name(self):
        return f'{self.hca}:{self.port}'

    def bytes_in(self):
        self.dwords_in_file.seek(0)
        return int(self.dwords_in_file.read()) * 4

    def bytes_out(self):
        self.dwords_out_file.seek(0)
        return int(self.dwords_out_file.read()) * 4

    def packets_in(self):
        self.packets_in_file.seek(0)
        return int(self.packets_in_file.read())

    def packets_out(self):
        self.packets_out_file.seek(0)
        return int(self.packets_out_file.read())

    def __repr__(self):
        return "<ibtop.Port %s at 0x%x>" % (repr(self.name()), id(self))

def print_iterator(it):
    for x in it:
        print(x, end=' ')
    print('')  # for new line


parser = ArgumentParser(description=__doc__)
parser.add_argument('-i', '--interval', type=int, required=True,
                    help='Amount of time in seconds between each report')
parser.add_argument('-c', '--count', type=int,
                    help='Number of reports generated')
args = parser.parse_args()

links = []
for hca in os.listdir(SYS_DIR):
    for port in os.listdir(f'{SYS_DIR}/{hca}/ports'):
        with open(f'{SYS_DIR}/{hca}/ports/{port}/state') as state_file:
            if 'ACTIVE' in state_file.read():
                links.append(Link(hca, port))

link_len = 12
mbps_len = 12
kpps_len = 12

header = '\n'
header += f'{"Link":{link_len}} {"Mbps in":>{mbps_len}} {"Mbps out":>{mbps_len}} {"kpps in":>{kpps_len}} {"kpps out":>{kpps_len}}'
header += '\n'
header += '=' * (link_len + 2 * mbps_len + 2 * mbps_len + 4)

bytes_in_start = list(map(Link.bytes_in, links))
bytes_out_start = list(map(Link.bytes_out, links))
packets_in_start = list(map(Link.packets_in, links))
packets_out_start = list(map(Link.packets_out, links))

period = args.interval
while True:
    time.sleep(period)
    bytes_in_now = list(map(Link.bytes_in, links))
    bytes_out_now = list(map(Link.bytes_out, links))
    packets_in_now = list(map(Link.packets_in, links))
    packets_out_now = list(map(Link.packets_out, links))
    bytes_in_delta = list(starmap(int.__sub__, zip(bytes_in_now, bytes_in_start)))
    bytes_out_delta = list(starmap(int.__sub__, zip(bytes_out_now, bytes_out_start)))
    packets_in_delta = list(starmap(int.__sub__, zip(packets_in_now, packets_in_start)))
    packets_out_delta = list(starmap(int.__sub__, zip(packets_out_now, packets_out_start)))
    labels = list(map(lambda l: f'{l.name():{link_len}}', links))
    mbps_in = list(map(lambda x: f'{x * 8 / period / 1e6:>{mbps_len}.3f}', bytes_in_delta))
    mbps_out = list(map(lambda x: f'{x * 8 / period / 1e6:>{mbps_len}.3f}', bytes_out_delta))
    kpps_in = list(map(lambda x: f'{x / period / 1e3:>{kpps_len}.3f}', packets_in_delta))
    kpps_out = list(map(lambda x: f'{x / period / 1e3:>{kpps_len}.3f}', packets_out_delta))
    print(header)
    list(starmap(print, zip(labels, mbps_in, mbps_out, kpps_in, kpps_out)))

    # send measurements to telegraf
    send_to_telegraf(labels, mbps_in, mbps_out, kpps_in, kpps_out)


    bytes_in_start = bytes_in_now
    bytes_out_start = bytes_out_now
    packets_in_start = packets_in_now
    packets_out_start = packets_out_now
    if args.count is not None:
        args.count -= 1
        if args.count == 0:
            sys.exit(0)
