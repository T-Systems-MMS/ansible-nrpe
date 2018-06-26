NRPE
=========

Ansible role to install and configure NRPE

Requirements
------------

- git if you want to checkout additional NRPE-checks from a custom repository

Role Variables
--------------

| variable | default value | description |
|---|---|---|
| nrpe_additional_groups | ``                                     | List of additional groups the NRPE user should belong to. |
| nrpe_allowed_hosts     | `127.0.0.1,172.29.70.2`                | List of IP addresses or hostnames that are allowed to talk to the NRPE daemon. |
| nrpe_check_list        | ``                                     | List of NRPE checks to insert into the configuration. |
| nrpe_checks_repository | ``                                     | URL of git-repository that contains additional NRPE-checks to be checked out. |
| nrpe_group             | `nrpe`                                 | Effective group that the NRPE daemon should run as. |
| nrpe_include_directory | `/etc/nrpe.d/`                         | Directive to include definitions from config files. |
| nrpe_pid_file          | `/var/run/nrpe/nrpe.pid`               | Name of the file in which the NRPE daemon should write it's process ID number. |
| nrpe_plugins_directory | `/home/nrpe/bin/`                      | Path where to copy the NRPE checks from the git-repository to. |
| nrpe_port              | `5666`                                 | Port number NRPE should wait for connections on. |
| nrpe_server_address    | `"{{ ansible_default_ipv4.address }}"` | Address that NRPE should bind to. |
| nrpe_user              | `nrpe`                                 | Effective user that the NRPE daemon should run as. |


Dependencies
------------
- none

Example Playbook
----------------

Install and configure NRPE with the default configuration:

    - hosts: servers
      roles:
         - { role: nrpe }


Install and configure NRPE with the additional settings configuration:

    - hosts: servers
      vars:
        nrpe_server_address: 127.0.0.1
        nrpe_checks_repository: "https://git.example.com/nrpe_checks.git"
        nrpe_additional_groups:
          - apache
      roles:
         - { role: nrpe }


License
-------

GPLv3

Author Information
------------------

Sebastian Gumprich
