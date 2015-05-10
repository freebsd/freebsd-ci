jenkins_user:
  user.present:
    - name: jenkins
    - uid: 8180
    - gid: 8180
    - fullname: Jenkins CI
    - home: /usr/local/jenkins
    - shell: /bin/sh

jenkins_group:
  group.present:
    - name: jenkins
    - gid: 8180

jenkins_sshkey:
  ssh_auth.present:
    - user: jenkins
    - source: salt://ssh_keys/jenkins.id_rsa.pub

install_java:
  pkg.installed:
    - name: openjdk8
