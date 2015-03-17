/usr/local/bin/salt \* pkg.audit:
  cron.present:
    - identifier: pkg.audit
    - user: root
    - minute: 30
    - hour: 6
    - daymonth: '*/2'
