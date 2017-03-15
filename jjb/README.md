[Jenkins Job Builder](http://docs.openstack.org/infra/jenkins-job-builder/) config for FreeBSD CI jobs

Setup:
- Install jenkins job builder form source (recommended) or ports/pkg `devel/py-jenkins-job-builder`
- `cp jenkins_jobs.ini.sample jenkins_jobs.ini`
- Edit `jenkins_jobs.ini` for your credenticals of ci.FreeBSD.org
  (https://ci.freebsd.org/me/configure -> "show api token")

Update jenkins jobs:
`make`

---

### Install jenkins job builder from source ###

.zshrc
```zsh
PATH=~${PATH}:~/local/bin
export PYTHONPATH=~/local/lib/python2.7/site-packages
```

install latest jenkins-job-builder
```sh
git clone https://github.com/openstack-infra/jenkins-job-builder.git
cd jenkins-job-builder
python setup.py install --prefix=~/local
```
