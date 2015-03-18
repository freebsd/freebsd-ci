etcupdate:
  pkg.latest
  
etcupdate extract:
  cmd.run:
    - creates: /var/db/etcupdate/hosts
  require:
    - pkg: etcupdate
