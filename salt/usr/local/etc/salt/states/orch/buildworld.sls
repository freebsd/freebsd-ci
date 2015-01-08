installkernel:
  salt.state:
    - tgt: {{ pillar['node'] }}
    - sls:
      - buildworld.installkernel

reboot_1:
  salt.function:
    - name: system.reboot
    - tgt: {{ pillar['node'] }}
    - require:
      - salt: installkernel

wait_for_reboot_1:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list:
      - {{ pillar['node'] }}
    - require:
      - salt: reboot_1

installworld:
  salt.state:
    - tgt: {{ pillar['node'] }}
    - sls:
      - buildworld.installworld
    - require:
      - salt: wait_for_reboot_1

reboot_2:
  salt.function:
    - name: system.reboot
    - tgt: {{ pillar['node'] }}
    - require:
      - salt: installworld

wait_for_reboot_2:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list:
      - {{ pillar['node'] }}
    - require:
      - salt: reboot_2

