installkernel:
  cmd.run:
    - name: |
        svn update /usr/src
        cd /usr/src
        make -j `sysctl -n hw.ncpu` buildworld
        make -j `sysctl -n hw.ncpu` buildkernel
        make installkernel
