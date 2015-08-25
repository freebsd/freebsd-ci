# TODO: Factor out monit away from jenkins stuff
Install monit:
  pkg.installed:
    - name: monit

rc-conf-salt-section:
  file.blockreplace:
    - name: /etc/rc.conf
    - marker_start: "# START SALT MANAGED SECTION - DO NOT EDIT #"
    - marker_end: "# END MANAGED SECTION #"
    - append_if_not_found: True
    - show_changes: True

Enable Monit in rc.conf:
  file.accumulated:
    - filename: /etc/rc.conf
    - name: enable-monit
    - text: 'monit_enable="YES"'
    - require_in:
      - file: rc-conf-salt-section

Enable Jenkins in rc.conf:
  file.accumulated:
    - filename: /etc/rc.conf
    - name: enable-jenkins
    - text: 'jenkins_enable="YES"'
    - require_in:
      - file: rc-conf-salt-section

cp monitrc.sample monitrc:
  cmd.run:
    - cwd: /usr/local/etc/
    - creates: /usr/local/etc/monitrc

monitrc includes monit.d:
  file.append:
    - name: /usr/local/etc/monitrc
    - text: "include /usr/local/etc/monit.d/*"

monit.d exists:
  file.directory:
    - name: /usr/local/etc/monit.d

/usr/local/etc/monit.d/jenkins:
  file.managed:
    - require:
      - file: /usr/local/etc/monit.d
    - contents: |
        set mailserver mx1.freebsd.org
        check process jenkins with pidfile /var/run/jenkins/jenkins.pid
          start program = "/usr/sbin/service jenkins start"
          stop program = "/usr/sbin/service jenkins stop"
          #if failed host jenkins.freebsd.org port 443 type tcpssl protocol http
          #    request "/some/path" hostheader "domain.com"
          #    with timeout 5 seconds
          #then alert # Optional, alert: is slow service!
          if failed host jenkins.freebsd.org port 443 type tcpssl protocol http
              request "/" hostheader "jenkins.freebsd.org"
              content = "FreeBSD"
              with timeout 15 seconds
              3 times within 4 cycles
          then restart
          #if 3 restarts within 15 cycles then timeout
          alert jenkins-admin@freebsd.org

monit:
  service.running:
    - enable: True
    - require:
      - pkg: monit
      - file: /usr/local/etc/monitrc
      - file: /usr/local/etc/monit.d/jenkins
    - watch:
      - file: /usr/local/etc/monitrc
      - file: /usr/local/etc/monit.d/jenkins

