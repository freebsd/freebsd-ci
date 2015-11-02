# List of packages which can be installed on all nodes.
# 
# To install on all nodes:
#    salt '*' state.apply packages_common
#
# To install on node foo:
#    salt foo state.apply packages_common 
packages_common:
  pkg.installed:
    - pkgs:
      - devel/arcanist
      - devel/jenkins
      - java/openjdk8
      - lang/python
      - shells/bash
      - shells/zsh
      - sysutils/py-salt
      - textproc/igor
