#!/usr/local/bin/python3

from http.server import BaseHTTPRequestHandler, HTTPServer
import base64
import configparser
import errno
import json
import os
import sys

key = None
basedir = '/home/artifact/snapshot'

def set_link(x):
    branch = x['branch']
    revision = 'r' + str(x['revision'])
    target = x['target']
    target_arch = x['target_arch']
    link_type = x['link_type']

    dst = os.path.join(branch, link_type, target, target_arch)
    dst_dir = os.path.dirname(os.path.join(basedir, dst))
    dst_base = os.path.basename(dst)
    os.makedirs(dst_dir, exist_ok=True)
    os.chdir(dst_dir)
    src = os.path.join('../..', revision, target, target_arch)
    try:
        os.symlink(src, dst_base)
    except OSError as e:
        if e.errno == errno.EEXIST:
            os.remove(dst_base)
            os.symlink(src, dst_base)

    return "{} -> {}".format(dst, src)

class RequestHandler(BaseHTTPRequestHandler):

    def do_POST(self):
        global key

        auth_header = self.headers['Authorization']

        if auth_header == ('Basic ' + key):
            length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(length).decode('utf-8')
            json_data = json.loads(post_data)

            msg = None
            try:
                r = set_link(json_data)
                self.send_response(201)
                msg = 'Link created: {}\n'.format(r)
            except:
                self.send_response(500)
                msg = 'Link not created\n'

            self.send_header('Content-type', 'text/html; charset=UTF-8')
            self.end_headers()

            self.wfile.write(bytes(json.dumps(msg), 'utf-8'))

        elif auth_header is None:
            self.send_response(401)
            self.send_header('WWW-Authenticate', 'Basic realm=\"artifact\"')
            self.send_header('Content-type', 'text/html; charset=UTF-8')
            self.end_headers()

            msg = 'No auth header received\n'
            self.wfile.write(bytes(json.dumps(msg), 'utf-8'))

        else:
            self.send_response(403)
            self.send_header('WWW-Authenticate', 'Basic realm=\"artifact\"')
            self.send_header('Content-type', 'text/html; charset=UTF-8')
            self.end_headers()

            msg = 'Auth header wrong\n'
            self.wfile.write(bytes(json.dumps(msg), 'utf-8'))

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print('Usage: ' + sys.argv[0] + ' set-link.ini')
        sys.exit()

    config_file = sys.argv[1]
    config = configparser.ConfigParser()
    config.read(config_file)
    username = config['set-link']['username']
    password = config['set-link']['password']
    log_file = config['set-link']['log_file']

    key = base64.b64encode(bytes(username + ':' + password, 'ascii')).decode('ascii')

    sys.stderr = open(log_file, 'a')

    server_address = ('127.0.0.1', 4080)
    httpd = HTTPServer(server_address, RequestHandler)
    httpd.serve_forever()
