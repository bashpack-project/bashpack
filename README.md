# Bashpack

Bashpack is a user-friendly Linux toolbox.
It has been designed for unexperimented Linux users for their day to day tasks and also for IT teams who needs to ensure security on their Linux laptop park.
You can easily setup automations with the differents options.

## Features
* (available)    Unified Linux updates (APT and Snapcraft packages).
* (incoming)     Unified Linux updates (firmwares with [fwupd](https://github.com/fwupd/fwupd)).
* (incoming)     Linux firewall security (close ports with nftables - Docker compatible).
* (incoming)     Routes over VPN to one or many points (OpenVPN compatible).

## Usage
**Commands & options** are listed with the command
```javascript
bp --help
```

**Builtin automations** are automatically configured with Systemd on your system



## Management steps

Copy/paste the following command blocks on your Linux terminal to manage yur Bashpack installation.
_You must be sudo._
_Once installed, Bashpack will automatically update itself (it checks for updates once a day)._

** Installation **
```javascript
curl -sL https://raw.githubusercontent.com/bashpack-project/bashpack/main/bashpack.sh -o bashpack.sh \
 && chmod +x bashpack.sh \
 && sudo ./bashpack.sh -i
```



** Update **
```javascript
sudo ./bashpack.sh -u
```

** Uninstallation **
```javascript
sudo ./bashpack.sh --self-delete
```


