#!/usr/local/bin/python3

from http.server import BaseHTTPRequestHandler, HTTPServer
import base64
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
    build_type = x['build_type']

    dst = os.path.join(basedir, branch, build_type, target, target_arch)
    dst_dir = os.path.dirname(dst)
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
                set_link(json_data)
                self.send_response(201)
                msg = 'Link created\n'
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

def main():
    server_address = ('127.0.0.1', 4080)
    httpd = HTTPServer(server_address, RequestHandler)
    httpd.serve_forever()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print('Usage: ' + sys.argv[0] + ' [username:password]')
        sys.exit()
    key = base64.b64encode(bytes(sys.argv[1], 'utf-8')).decode('utf-8')
    main()
