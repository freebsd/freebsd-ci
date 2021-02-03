#!/usr/local/bin/python3

import http.client
import base64
import json
import os

x = {}
x['job_name'] = os.environ['JOB_NAME']
if os.environ.get('GIT_COMMIT', False):
    x['commit'] = os.environ['GIT_COMMIT']
else:
    x['revision'] = os.environ['SVN_REVISION']
x['branch'] = os.environ['FBSD_BRANCH']
x['target'] = os.environ['FBSD_TARGET']
x['target_arch'] = os.environ['FBSD_TARGET_ARCH']
x['link_type'] = os.environ['LINK_TYPE']
json_req = json.dumps(x)

if os.environ.get('ARTIFACT_SERVER', False):
    connections = http.client.HTTPSConnection(os.environ['ARTIFACT_SERVER'], 8182)
else:
    connections = http.client.HTTPSConnection('artifact.ci.freebsd.org', 8182)

username = os.environ['ARTIFACT_CRED_USER']
password = os.environ['ARTIFACT_CRED_PASS']
key = base64.b64encode(bytes(username + ':' + password, 'ascii')).decode('ascii')

headers = {}
headers['Authorization'] = 'Basic {}'.format(key)
headers['Content-Type'] = 'application/json'

try:
    connections.request('POST', '/', json_req, headers)
    response = connections.getresponse()
    print(response.read().decode())
except:
    print('Call set-link failed.\n')
