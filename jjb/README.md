[Jenkins Job Builder](http://docs.openstack.org/infra/jenkins-job-builder/) config for FreeBSD CI jobs

## Directory Structure

The JJB configuration is organized into logical directories:

- `config/` - Global defaults and configuration
- `scm/` - Source Control Management configurations for FreeBSD src/doc
- `macros/` - Reusable builders, publishers, and wrappers
  - `builders.yaml` - Build steps and parameters
  - `publishers.yaml` - Result publishers and artifact handling
  - `jail.yaml` - Jail-specific operations
  - `notifications.yaml` - Email notification configurations
- `templates/` - Job templates organized by type
  - `build-templates.yaml` - Build job templates
  - `test-templates.yaml` - Test job templates
  - `lint-templates.yaml` - LINT job templates
  - `image-templates.yaml` - Image build templates
- `projects/` - Project definitions organized by branch
  - `main-branch.yaml` - Main branch projects
  - `stable-14.yaml` - Stable/14 branch projects
  - `stable-13.yaml` - Stable/13 branch projects
  - `doc-projects.yaml` - Documentation projects
- `utilities/` - Utility and maintenance jobs

## Setup

- Install jenkins job builder from source (recommended) or ports/pkg `devel/py-jenkins-job-builder`
- `cp jenkins_jobs.ini.sample jenkins_jobs.ini`
- Edit `jenkins_jobs.ini` for your credentials of ci.FreeBSD.org
  (https://ci.freebsd.org/me/configure -> "show api token")

## Update jenkins jobs

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
