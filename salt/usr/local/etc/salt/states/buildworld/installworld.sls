installworld:
  cmd.run:
    - name: |
        cd /usr/src
        mergemaster -p
        make installworld
        mergemaster -iUF
        yes | make delete-old
        yes | make delete-old-libs
        cd /usr/obj && chflags -R noschg * && rm -rf *
