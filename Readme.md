# r2ban - Abuse Report Generator for File2ban #
===========================

This Ruby software was written to create an abuse report Generator for the **Fail2Ban: https://github.com/fail2ban/fail2ban** 

It is a simple Ruby code that can call as Fail2ban action and take in input an ip and the service on which there is an attack and try to resolve the ip on RIPE db trough whois to search for an abuse mail address and if there is one send a mail to report an abuse from ip registered in their network.

## Menu
- [Prerequisites](#prerequisites)
- [Installation](#Setup)
- [Configuration](#configuration)
- [Fail2ban integration](#integration)
- [Chngelog](#changelog)
- [TODO](#todo)
- [License](#license)
- [Credits](#credits)
- [Author](#author)



<a name="prerequisites"/>
## Prerequisites

In the actual revision r2ban working on a machine with this requisites:
- Gnu\Linux Distribution (I've tested on Centos 5.X and 6.X)
- Ruby 2.1.1
- Mail gem installed in a wrapper
- Fail2Ban (v. 0.9.0 or +)
- whois

In the next releases I test even Debian and Ubuntu OS

<a name="Setup"/>

## Installation

### Introduction
Due to limitations of the environment under which runs fail2ban his process you had to create a ruby wrapper to install some gems and runs r2ban.
An extensive guide can be found on my blog at this link: [Ruby Wrapper](http://www.stanzinofree.net)
In short lines you can follow those commands to have a wrapper instance to use with:

    rvm gemset create r2ban # r2ban is the name I give at my wrapper
    rvm gemset use r2ban # move on new wrapper
    gem install mail # install the mail gem
    gem list # check if mail is installed correctly

After you have created this you can check where is ruby wrapper compiler searching for rvm:

    wchich rvm

After you know where is ruby (/usr/local/rvm) move in that folder and search for wrapper folder (wrappers/ruby-2.1.1@r2ban in my case) this is the path of the ruby instance we must use to run r2ban:

    /usr/local/rvm/wrappers/ruby-2.1.1@r2ban/ruby


:heavy_exclamation_mark: **ATTENTION**
There is a limitation in Centos 5 that can't use shebang with @ in the path(in the next release I try even Debian and Ubuntu to search if there is the same limit) so when we invoke it in fail2ban we had to explicit declarate the compiler path in the execution command.

<a name="configuration" />
## Configuration

In the config folder there are 4 files:
- [banner.json](#banner.json)
- [banner.txt](#banner.txt)
- [config.json](#config.json)
- [mail_config.json](#mail_config.json)

<a name="banner.json" />
### banner.json
This file contain a simple footer banner (in the next release I'll remove it), now there is a check in start of the script that if missing this file you can't send mail

<a name="banner.txt" />
### banner.txt
This file contain the footer part of the mail, you can modify it if you want but I ask to not modify it to help me to know my work to others in the hope to find a future Job.

<a name="config.json" />
### config.json
This file contain some configuration that you can modify:
- prod - can be true or false, when it's false the mail is not send
- noise - can be true or false, is thinked to be level value
- template - the name of template(without .erb) you want use, it must be placed in /template/ 

<a name="mail_config.json" />
### mail_config.json
This contain the values you had to change to best use r2ban:
- from - is the address you use to send mail from
- cc - is the address you use to cc mail (the to is the abuse address)
- team_name - is used as sign of mail, it's not vital but look like me geeky :)

In the template folder there is 1 template file:
- [r2ban.erb](#r2ban.erb)

<a name="r2ban.erb" />
### r2ban.erb
This is the core of the mail, it contain the css, the html structure and the text used for mail, it is an erb template so I suggest to copy this file before make change.
If you want a guide to modify this file you can follow my blog [Stanzinofree](http://www.stanzinofree.net) where there are how-to articles to modify erb files and create new ones


<a name="integration" />
## Fail2ban integration
Now that r2ban is configure it must be included in Fail2ban.
The steps are:
- [create command file](#create_command)
- [modify jail file](#modify_jail)

<a name="create_command" />
To create our custom command file under the Fail2ban folder action.d we use the template dummy.conf
If Fail2ban is installed in default folders the steps are:

    cd /etc/fail2ban/action.d
    cp dummy.conf r2ban.conf
    vi r2ban.conf

If you want you can find an r2ban.conf on my site at this link [r2ban.conf](http://www.stanzinofree.net/r2ban/r2ban.conf)

The most important thing is the actionban line:

    actionban = /usr/local/rvm/wrappers/ruby-2.1.1@r2ban/ruby /opt/r2ban/r2ban.rb <ip> <name>

<a name="modify_jail" />
### Modify Jail File
Now that even the command file is ready we say to our jail.local file that can use our r2ban to send automate mail to abuse mail.
The jail.local file is located in root folder of Fail2ban so in standard installation /etc/fail2ban/jail.local

**NOTE**: if you don't have jail.local I suggest you to create one to work with so if you want to upgrade fail2ban you are sure you can maintain the canges you made to the jail.

    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

So in a tipical Jail we modify the action line in this way

    [SSH]
    enabled = true
    filter = sshd
    action = iptables[name=SSH, port=ssh, protocol=tcp]
             r2ban[name=SSH]
    logpath = /var/log/secure
    maxretry = 3

<a name="changelog">
## Changelog

v 0.2
- Separated mail config from software config
- Create template folder and template name value variable in config file
- Insert not prod function to test variable and test workflow of software
- If not abuse mail found use cc as to address

v 0.1
- Release software

<a name="todo" />
## TODO
- Division from text template and css template
- Creation of software config file and move actual config in mail_conf file
- Updating Software function
- Attach log function

<a name="license" />
## License
This software is released under [GPL v3](http://www.gnu.org/licenses/gpl-3.0.txt "GPL v3")

<a name="credits" />
## Credits

Thanks to the author of the module I use in my software and the author of templates

- [Ink template mail from Zurb](http://zurb.com/ink/ "INK")
- [Fail2ban](https://github.com/fail2ban/fail2ban "Fail2ban")
- [Mail gem](https://github.com/mikel/mail "Mail")

<a name="author" />
## Author
**Author**: Middei Alessandro
**Contact**: alexitconsulting@gmail.com
**Website**: www.stanzinofree.net
**Skype**:alessandro.middei
