# FreeBSD CI Salt Orachestration

This directory is for salt based orchestration for freebsd ci system

Example:

Orchestrate a "buildworld" style OS upgrade on jenkins-10.freebsd.org

```
salt-run state.orch orch.buildworld pillar="{node: 'jenkins-10.freebsd.org' }"
```

