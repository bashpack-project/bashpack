# Bashpack changes

The released versions changelogs below are only about the main repository.

### 2.0.0
*incoming release date*
##### Added
- Log support in /var/log/bashpack/
- YUM updates support
- Firewall management (nftables only for now)
- This changelog file :D

##### Modified
- Entirely rewritten to be compliant with POSIX systems
- Update process improved to avoid downloading too much files
- Installation process improved by automatically detect the better $PATH
- Sub command "verify" is now more used in installations process
- Sub command "verify" can now detect presence of required commands
- Config file rename from bashpack_config to bashpack.conf
- Detection of systemd improved to be able to install on incompatible systems
- Detection of pkg-config improved to be able to install on incompatible systems
- Moving sources from /usr/local/src/ to /opt/

------------
### 1.1.1
*2024/10/06*
##### Added
- Sub command "verify" now replaces command option "-t"
- Sub command "verify" can now test repository reachability and test releases download/extraction

##### Modified
- Update process is now taking in account the configuration file and the user custom values
- Update process is now avoiding undesirables uninstallations

------------
### 1.0.4
*2024/07/23*
##### Added
- Configuration directory available at /etc/bashpack/
- Publications stages with 3 repositories (main, unstable & dev)
- New option to test installation "-t" (testing files presence only for now)

##### Modified
- Detect if currently already in its latest version to avoid new installation at each update

------------
### 0.3.0
*2024/07/04*
##### Added
- Firmware upgrades for bare-metal systems (fwupd)