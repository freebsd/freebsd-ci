#!/usr/local/bin/python3

import base64
import configparser
import urllib.parse
import urllib.request

config = configparser.ConfigParser()
config.read('config.ini')

file = open('script.groovy', 'r', encoding='UTF-8')
groovy_script = file.read()
file.close()

url = "{}/scriptText".format(config['general']['host'])
parameters = {'script':groovy_script}
data = urllib.parse.urlencode(parameters).encode('utf-8')
req = urllib.request.Request(url=url, data=data)

username = config['cred']['username']
password = config['cred']['password']
cred = base64.b64encode('{}:{}'.format(username,password).encode('utf-8'))
req.add_header("Authorization", "Basic {}".format(cred.decode('utf-8')))

s = urllib.request.urlopen(req)
result = s.read().decode('utf-8')
print(result)
