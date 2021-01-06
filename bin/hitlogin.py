#!/bin/python

import urllib.request
import urllib.parse
from time import sleep
import re
import sys
import os


def checkssid():
    if sys.platform == "linux":
        if not os.popen('iw wlp1s0 link | grep "HIT-WLAN"').read():
            print('not connected to hit-wlan')
            return False
    elif sys.platform == "darwin":
        print('I\'m not familiar with this...')
        return False
    elif sys.platform == "win32":
        if not os.popen('netsh wlan show interfaces | findstr "HIT-WLAN"').read():
            print('not connected to hit-wlan')
            return False
    return True  # connected to hit-wlan


def check_redirect():
    urls = ['http://ip111.cn', 'http://www.hit.edu.cn',
            'http://202.118.253.94:8080/']
    d = ''
    for url in urls:
        print('try urlopen({})'.format(url))
        try:
            # d = <script>top.self.location.href='http://202.118.253.94:8080/eportal/index.jsp?wlanuserip=7dbf125a18dd78b3e18525acca665ac1&wlanacname=f43d705bb44eb56d54f2c8d6500609b4&ssid=&nasip=4eea2cd266564f25c9e41f29ed4b9a83&snmpagentip=&mac=76f76fc7fafd1e2f0b0bbea41c0537eb&t=wireless-v2&url=f8443b948faadebe646798b128b82dab8a22ddcd0ed385ec&apmac=&nasid=f43d705bb44eb56d54f2c8d6500609b4&vid=ce2e310104de2887&port=d29e3cfa158d1b87&nasportid=6e542cb8cfadb35187e8ec13360ddff07cff5df5ba1eee5c5262e7be872edfc1'</script>
            d = urllib.request.urlopen(url, timeout=5).read().decode()
            break
        except:
            print('urlopen({}) error'.format(url))
    if not d:
        return
    p = r"<script>top.self.location.href='(.*?)'</script>"
    g = re.match(p, d)
    if not g:
        print('already logged in')
        return  # already logged in
    return urllib.parse.urlparse(g.group(1))


def login(url, data):
    try:
        r = urllib.request.urlopen(url, data=data.encode())
        print(r.read().decode())
    except:
        return


def main():
    if not checkssid():
        return
    urlparsed = check_redirect()
    if not urlparsed:
        return
    print('got redirect url')
    userId = 'xxx'
    password = 'xxx'
    # hitlogin.py userId password
    if len(sys.argv) > 2:
        userId = sys.argv[1]
        password = sys.argv[2]
    url = 'http://{netloc}{path}'.format(netloc=urlparsed.netloc,
                                         path='/eportal/InterFace.do?method=login')
    data = 'userId={}&password={}&service=&operatorPwd=&operatorUserId=&passwordEncrypt=false&queryString={}'.format(
        urllib.parse.quote(userId), urllib.parse.quote(password), urllib.parse.quote(urlparsed.query))
    # print(url) # http://202.118.253.94:8080/eportal/InterFace.do?method=login
    # print(data) # userId=xxx&password=xxx&service=&operatorPwd=&operatorUserId=&passwordEncrypt=false&queryString=wlanuserip%3D7dbf125a18dd78b3e18525acca665ac1%26wlanacname%3Df43d705bb44eb56d54f2c8d6500609b4%26ssid%3D%26nasip%3D4eea2cd266564f25c9e41f29ed4b9a83%26snmpagentip%3D%26mac%3D76f76fc7fafd1e2f0b0bbea41c0537eb%26t%3Dwireless-v2%26url%3Df8443b948faadebe646798b128b82dab8a22ddcd0ed385ec%26apmac%3D%26nasid%3Df43d705bb44eb56d54f2c8d6500609b4%26vid%3Dce2e310104de2887%26port%3Dd29e3cfa158d1b87%26nasportid%3D6e542cb8cfadb35187e8ec13360ddff07cff5df5ba1eee5c5262e7be872edfc1
    login(url, data)


if __name__ == "__main__":
    while True:
        main()
        sleep(60)
