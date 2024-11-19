# Bashpack changes

The released versions changelogs below are only about the main repository.

### 2.0.0
*2024/11/19*
##### Added
- Log support in /var/log/bashpack/ and "--get-logs" option
- Sub command "update" support of DNF (and YUM fallback)
- Sub command "firewall" for firewall management (nftables only for now)
- This changelog file :D

##### Modified
- Entirely rewritten to be compliant with POSIX systems
- Self update improved to avoid downloading too much files
- Self update can now be forced with "-u --force" option 
- Self installation improved by automatically detect the better $PATH
- Self installation can now read a given publication with "-i publication_name" 
- Sub command "verify" is now more used in installation process
- Sub command "verify" can now detect presence of required commands
- Config file renamed from bashpack_config to bashpack.conf
- Detection of systemd improved to be able to install on compatible systems only
- Detection of pkg-config improved to be able to install on compatible systems only
- Moving sources from /usr/local/src/ to /opt/

##### Removed
- Sub command "verify" download/extraction

------------
### 1.1.1
*2024/10/06*
##### Added
- Sub command "verify" now replaces command option "-t"
- Sub command "verify" can now test repository reachability and test releases download/extraction

##### Modified
- Self update is now taking in account the configuration file and the user custom values
- Self update is now avoiding undesirables uninstallations

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