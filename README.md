# Bashpack

Bashpack is a **user-friendly Linux toolbox**.

It has been designed for helping **Linux** users on their **day to day tasks**.
It can also be useful for IT teams who needs to ensure security on their Linux park.

You can easily setup **automations** with the differents **options**.

<br>

## Features
* (available)    Unified Linux updates ([APT](https://fr.wikipedia.org/wiki/Advanced_Packaging_Tool) and [Snapcraft](https://snapcraft.io/) packages (Snapcraft is not installed with this script, it just handled if already used)).
* (incoming)     Unified Linux updates (firmwares with [fwupd](https://github.com/fwupd/fwupd)).
* (incoming)     Secure Linux firewall (close ports with [nftables](https://wiki.nftables.org/wiki-nftables/index.php/Main_Page) ([Docker](https://www.docker.com/) compatible)).
* (incoming)     Routes over VPN to one or many points ([OpenVPN](https://openvpn.net/) compatible).

<br>

## Quick start
Copy/paste the following command blocks on your Linux terminal to manage your Bashpack installation.
* _You must be sudo._
* _[Systemd](https://systemd.io/) installations only: Once installed, Bashpack will automatically update itself (it checks for updates once a day)._

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


<br>

### Unified Linux updates
Launch a pre-validated update of everything on your system:
```javascript
sudo bp update -y
```

[Systemd](https://systemd.io/) installations only:
Check next update:
```javascript
sudo bp update --when
```
Get logs from last update:
```javascript
sudo bp update --get-logs
```

<br>


### Secure Linux firewall
Incoming

<br>


### Routes over VPN
Incoming

<br>


## Disclaimer
For now, Bashpack is not POSIX.