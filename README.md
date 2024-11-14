# Bashpack

Bashpack is a **user-friendly** Linux toolbox that has been designed to **quickly secure any Linux distro**.

It can be used for deployment purposes, or even by novices users (it doesn't require any specific knowledge).

<br>

## Features
* Unified Linux updates \
_one command to conntrol them all_
    - [APT](https://wiki.debian.org/Apt)
    - [DNF](https://rpm-software-management.github.io/)
    - [YUM](http://yum.baseurl.org/)
    - [Snap](https://snapcraft.io/)
    - [fwupd](https://github.com/fwupd/fwupd) (firmwares)
* Secured Linux firewall
_block inbounds and simplify rule creation_
    - [nftables](https://wiki.nftables.org/wiki-nftables/index.php/Main_Page)

<br>


## Quick start
Copy/paste the following command blocks on your Linux terminal to manage your Bashpack installation.

**Install**
```javascript
curl -sL https://raw.githubusercontent.com/bashpack-project/bashpack/main/bashpack.sh -o bashpack.sh \
 && chmod +x bashpack.sh \
 && sudo ./bashpack.sh -i \
 && rm bashpack.sh
```

**Update**
```javascript
sudo bp -u
```

**Uninstall**
```javascript
sudo bp --self-delete
```

<br>

## Usage
**Commands & options** are listed with the command:
```javascript
bp --help
```

<br>

### Command examples

#### Unified Linux updates
Launch a pre-validated update of everything on your system:
```javascript
sudo bp update -y
```

Check next update ([Systemd](https://systemd.io/) installations **only**):
```javascript
sudo bp update --when
```
Get logs from last update ([Systemd](https://systemd.io/) installations **only**):
```javascript
sudo bp update --get-logs
```

<br>


#### Secured Linux firewall
**Install** a ruleset
```javascript
sudo bp firewall -i
```

**Restore** a backuped ruleset (made automatically during an installation)
```javascript
sudo bp firewall --restore
```

**Disable** the firewall
```javascript
sudo bp firewall --disable
```

<br>

## FAQ
* Bashpack itself is POSIX, meaning it can be installed on any POSIX system. That being said, every specific distro software support needs to be added one by one in the sub commands.
* Root/sudo access is required.
* [Systemd](https://systemd.io/) is highly recommanded to benefit all the automations.
* Bashpack will automatically update itself ([Systemd](https://systemd.io/) installations only).
* [fwupd](https://github.com/fwupd/fwupd) is installed only if your system is bare-metal (only [Systemd](https://systemd.io/) installations can detect it).
* Multiple repositories exists, for production usage only the [main](https://github.com/bashpack-project/bashpack) one should be used.
