# Configuring multifactor authentication with Duo Unix
## Adding `duo_unix` to your `Puppetfile` 
In order to support multifactor authentication with Duo, you will first need to add the `duo_unix` Puppet module to your `Puppetfile` 
and define it in your [`main.tf`](https://github.com/ComputeCanada/magic_castle/tree/main/docs#419-puppetfile-optional). If you want to 
use the original version, you would add
```
mod 'iu-duo_unix', '4.0.1'
``` 
to your `Puppetfile`. However, note that this version does not support [CERN's documented implementation](https://cern-cert.github.io/pam_2fa/)
through `pam_duo`, but only `duo_login`. A [pull request](https://github.com/indiana-university/puppet-duo_unix/pull/38) has been opened to support `pam_duo`, 
but has not yet been merged. To use a version that supports `pam_duo`, you can add instead
```
mod 'iu-duo_unix',
    :git => 'https://github.com/mboisson/puppet-duo_unix.git',
    :ref => 'master'
```

## Adding `duo_unix` to your instances
You need to add the `duo_unix` module to your instances using Magic Castle [tags](https://github.com/ComputeCanada/puppet-magic_castle/tree/main?tab=readme-ov-file#magic_castlesite). 
For example, you can either recreate the `login` tag in your hieradata: 
```
magic_castle::site::tags:
  login:
    - profile::fail2ban
    - profile::cvmfs::client
    - profile::slurm::submitter
    - profile::ssh::hostbased_auth::client
    - profile::nfs::client
    - profile::freeipa::client
    - profile::rsyslog::client
    - duo_unix
```
or define a new tag, and apply it to your instances through the `main.tf`: 
```
magic_castle::site::tags:
  worldssh:
    - duo_unix
```
and then in your `main.tf`, add the `worldssh` tag to your `login` instance: 
```
    login  = { type = "...", tags = ["login", "public", "worldssh"], count = 1 }
```

## Adding your Duo configuration
In your hieradata file, add the following: 
```
duo_unix::usage: 'pam'
duo_unix::ikey: <your ikey>
duo_unix::skey: <your skey>
duo_unix::host: <your duo host>
duo_unix::motd: 'yes'
duo_unix::groups: '*,!centos'
duo_unix::pam_ssh_config::keyonly: true  # optional
``` 
where the last line is if you want to restrict the primary authentication to SSH keys only. Since this configuration contains
secrets, it is strongly recommended generate and upload [eyaml certificates](https://github.com/ComputeCanada/magic_castle/tree/main/docs#1013-generate-and-replace-puppet-hieradata-encryption-keys)
and use them to [encrypt your data](https://simp.readthedocs.io/en/master/HOWTO/20_Puppet/Hiera_eyaml.html).

## Caveat if you are using Terraform cloud
If you are using Terraform cloud for your deployment, adding multifactor authentication with Duo will break terraform's deployment of files through SSH.
In order to avoid this, you will need this [pull request](https://github.com/ComputeCanada/puppet-magic_castle/pull/340) merged in your fork of `puppet-magic_castle` 
or wait until this pull request is merged upstream. 


# Configuring `sudo`
## Adding `saz-sudo` to your `Puppetfile` 
If you want to configure `sudo` commands on your cluster, you will want to add the [`saz-sudo`](https://forge.puppet.com/modules/saz/sudo/readme) Puppet module to your `Puppetfile` 
and define it in your [`main.tf`](https://github.com/ComputeCanada/magic_castle/tree/main/docs#419-puppetfile-optional). You would add
```
mod 'saz-sudo', '8.0.0'
``` 
to your `Puppetfile`. 

## Adding `sudo` to your instances
You need to add the `sudo` module to your instances using Magic Castle [tags](https://github.com/ComputeCanada/puppet-magic_castle/tree/main?tab=readme-ov-file#magic_castlesite). 
For example, you can either recreate the `login` tag in your hieradata: 
```
magic_castle::site::tags:
  login:
    - profile::fail2ban
    - profile::cvmfs::client
    - profile::slurm::submitter
    - profile::ssh::hostbased_auth::client
    - profile::nfs::client
    - profile::freeipa::client
    - profile::rsyslog::client
    - sudo
```
or define a new tag, and apply it to your instances through the `main.tf`: 
```
magic_castle::site::tags:
  sudo:
    - sudo
```
and then in your `main.tf`, add the `sudo` tag to your instance: 
```
    login  = { type = "...", tags = ["login", "public", "sudo"], count = 1 }
```

## Adding your `sudo` configuration
Add the content of `sudoers` files to your hieradata. For example: 
```
sudo::ldap_enable: true
sudo::config_file_replace: false
sudo::prefix: '10-mysudoers_'
sudo::purge_ignore: '[!10-mysudoers_]*'
sudo::configs:
  'general':
    'content': |
      Cmnd_Alias ADMIN_ROOTCMD = /bin/cat *, /bin/ls *, /bin/chmod *, /bin/vim *, /usr/bin/su -, /bin/yum *, /bin/less *, /bin/grep *, /bin/kill *, /usr/sbin/reboot
      %admin ALL=(ALL)      NOPASSWD: ADMIN_ROOTCMD
```

# Configuring a system's `cron` 
## Adding `puppet-cron` to your `Puppetfile` 
If you want to configure `cron` commands on your cluster, you will want to add the [`puppet-cron`]([https://forge.puppet.com/modules/saz/sudo/readme](https://github.com/voxpupuli/puppet-cron)) Puppet module to your `Puppetfile` 
and define it in your [`main.tf`](https://github.com/ComputeCanada/magic_castle/tree/main/docs#419-puppetfile-optional). You would add
```
mod 'puppet-cron', '2.0.0'
``` 
to your `Puppetfile`. 

## Adding `cron` to your instances
You need to add the `cron` module to your instances using Magic Castle [tags](https://github.com/ComputeCanada/puppet-magic_castle/tree/main?tab=readme-ov-file#magic_castlesite). 
For example, you can either recreate the `login` tag in your hieradata: 
```
magic_castle::site::tags:
  login:
    - profile::fail2ban
    - profile::cvmfs::client
    - profile::slurm::submitter
    - profile::ssh::hostbased_auth::client
    - profile::nfs::client
    - profile::freeipa::client
    - profile::rsyslog::client
    - cron
```
or define a new tag, and apply it to your instances through the `main.tf`: 
```
magic_castle::site::tags:
  cron:
    - cron
```
and then in your `main.tf`, add the `sudo` tag to your instance: 
```
    login  = { type = "...", tags = ["login", "public", "cron"], count = 1 }
```

## Adding your `cron` configuration
Add the configuration to your hieradata. For example: 
```
cron::job:
  mii_cache:
    command: 'source $HOME/.bashrc; /etc/rsnt/generate_mii_index.py --arch sse3 avx avx2 avx512 &>> /home/ebuser/crontab_mii.log'
    minute: '*/10'
    hour: '*'
    date: '*'
    month: '*'
    weekday: '*'
    user: ebuser
    description: 'Generate Mii cache'
``` 
