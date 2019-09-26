import sys, os, time, signal
from subprocess import PIPE, Popen
from threading  import Thread
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
 
    
def send_to_telegraf(rate, device):

    now = datetime.datetime.now()
    timestamp = datetime.datetime.timestamp(now) * 1000000000 
    
    telegraf_string = "AllenIntegrationTest,AllenInstance=%s " % (device)
    telegraf_string += "allen_rate=%.2f " % (float(rate)) 
    telegraf_string += " %d" % timestamp 
    
    send(telegraf_string)





 
