install_sudo:
  pkg.installed:
    - name: sudo

install_sudoers:
  file.managed:
    - name: /usr/local/etc/sudoers
    - source: salt://jailer_sudoers
    - user: root
    - group: wheel
    - mode: 0440
    - require:
      - pkg: install_sudo
