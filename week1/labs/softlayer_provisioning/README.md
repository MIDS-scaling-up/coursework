# Provisioning VSes in SoftLayer

## Overview

Big data requires platforms that provide sufficient compute and storage resources to accommodate its volume and velocity. Cloud computing platforms fit the big data problem domain well: cloud systems cluster easily to provide aggregate storage and compute resources. In addition, they can be flexibly provisioned, deprovisioned, etc. The purpose of this assignment is to acquaint you with the SoftLayer cloud platform, management tools for SoftLayer, and additional software to manage cloud deployments.

## Tools Used

* SoftLayer Python library and bundled CLI tool `slcli`, https://pypi.python.org/pypi/SoftLayer/4.0.2. See also https://softlayer-api-python-client.readthedocs.org/en/latest/cli/
* `pip`, a Python package management tool, https://pip.pypa.io/en/stable/

## Preconditions

You must have a SoftLayer account; if you were not provided with one, or you cannot use the provided credentials to authenticate at https://control.softlayer.com/, please alert your instructor.

Access to a Unix shell—and experience with it—are assumed throughout the course. A terminal emulator in a recent version of any popular Linux distribution (Ubuntu or RedHat) or Mac OS X will work well. If you need help setting up a suitable Unix environment, or you need assistance using one, please alert an instructor.

## Getting Started

### Obtain SoftLayer API Key

Follow the instructions at http://knowledgelayer.softlayer.com/procedure/generate-api-key to generate an API key. The key is private credential information: keep it secret and speedily remove it if you suspect it has been compromised (see http://knowledgelayer.softlayer.com/procedure/remove-api-key for instructions). Retain this key for later configuration of the SoftLayer CLI tool.

### Install the Python interpreter and Pip
Python version 2.7 or newer and a complementing pip program are required for this lab’s tools. Below are shell commands and successful output to test your system. If something is amiss, follow the installation instructions that follow.

    python

    Python 3.4.3 (default, Mar 25 2015, 17:13:50)
    …
    >>>

(Use the key sequence CTRL-d to escape the REPL)

    pip --version
    pip 6.1.1 from /usr/lib/python3.4/site-packages (python 3.4)

#### Mac OS X Installation Steps

* Install Xcode from the Apple store
* Accept the `gcc` license agreement

    sudo gcc

* Install `pip`

    sudo easy_install pip

#### Ubuntu Linux Installation Steps

* Install tooling

    sudo apt-get update && sudo apt-get install python python-pip python-dev build-essential curl

### Install and configure the SoftLayer Python library

    sudo pip install SoftLayer
    slcli config setup

That last command will prompt you for your SoftLayer credentials; the default values for questions that provide them are sufficient.

## Working with SoftLayer VSes

SoftLayer virtual servers can be provisioned through slcli. The tool can order systems that are billed hourly or monthly and with varying configurations. In this course we’ll often provision low-RAM hourly virtual servers as demonstrated below.

Provision a new VS with a command like the following (note that you should replace the content in `<>`'s with your own values):

    slcli vs create --datacenter=dal09 --domain=<somedomain> --hostname=<some hostname> --os=CENTOS_7_64 --cpu=1 --memory=1024 --billing=hourly

(To understand available VS ordering options, consult `slcli vs create-options`; for help with CLI arguments, execute `slcli vs create --help`).

You can use `slcli` to query existing VSes, including those in being provisioned. During provisioning, find your VS with:

    slcli vs list

Once provisioned, you should see a public IP address in the "primary_ip" column like this:

    :..........:..................:................:...............:............:........:
    :    id    :     hostname     :   primary_ip   :   backend_ip  : datacenter : action :
    :..........:..................:................:...............:............:........:
    : 25719819 :     mediator     :   5.43.33.24   :  10.20.3.100  :   dal09    :   -    :
    ...

Once provisioned, use `slcli` to discover the system's root password (note, replace the content in `<>`'s with the id or IP address of your VS:

    slcli vs credentials <25719819>

    :..........:..........:
    : username : password :
    :..........:..........:
    :   root   : F7oglewp :
    :..........:..........:

Use the discovered facts and SSH to access a shell remotely (again, replace the sample content in `<>`'s):

    ssh root@<5.43.33.24>

Once you've successfully accessed the system's shell, deprovision it using the `slcli` tool:

    slcli vs cancel <id>

