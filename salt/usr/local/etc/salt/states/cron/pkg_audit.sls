pkg.audit.mail:
  cron.present:
    - name: '/usr/sbin/pkg audit -Fq |
    /usr/bin/mail -E -s "pkg audit vulnerable packages (`/bin/hostname -s`)"
    jenkins-admin@freebsd.org'
    - identifier: pkg.audit.mail
    - user: root
    - minute: 30
    - hour: 6
