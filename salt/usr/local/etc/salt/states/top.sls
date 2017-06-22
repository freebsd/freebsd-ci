base:
  '*':
    - ci
  'jenkins-9.freebsd.org':
    - monit
  jailer:
    - match: nodegroup
    - jailer
    - jenkins_slave
