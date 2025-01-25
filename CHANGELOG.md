# Bashpack changes

The released versions changelogs below are only about the main repository.

### 3.0.0
*Incoming release date*
##### Modified
- The CLI has been redesigned has a "script manager", to download/install/run/remove scripts as subcommands
- The CLI can now be installed offline by itself
- Anyone can now host a repository for its own subcommands (edit sourceslist option from the configuration directory) 
- Anyone can now host a repository for its own CLI (edit cli_url option from the configuration file)
- Repositories are compatibles with Github, but can also be simple directories listing web servers
- The CLI helper can now easily create an automation from a simple function to be able to automatically run a subcommand on the system (systemd only for now)
- When creating subcommands, the function "init_command()" can be used to run any requirements on the system (create automation, file etc... or anything else)
- Subcommands provided from this project has moved to the [commands repository](https://github.com/bashpack-project/commands)
- Subcommands "update" and "install" are now merged in the "package" subcommand
- Subcommand "verify" option "-c/--commands" replaced by "-d/--dependencies"
- Publication system has been removed and replaced by the configuration option "cli_url"

##### Fixed
- Subcommand "firewall" restoration option wasn't able to read the given file name

------------
### 2.0.0
*2024/11/19*
##### Added
- Log support in /var/log/bashpack/ and "--get-logs" option
- Subcommand "update" support of DNF (and YUM fallback)
- Subcommand "firewall" for firewall management (nftables only for now)
- This changelog file :D

##### Modified
- Entirely rewritten to be compliant with POSIX systems
- Self update improved to avoid downloading too much files
- Self update can now be forced with "-u --force" option 
- Self installation improved by automatically detect the better $PATH
- Self installation can now read a given publication with "-i publication_name" 
- Subcommand "verify" is now more used in installation process
- Subcommand "verify" can now detect presence of required commands
- Config file renamed from bashpack_config to bashpack.conf
- Detection of systemd improved to be able to install on compatible systems only
- Detection of pkg-config improved to be able to install on compatible systems only
- Moving sources from /usr/local/src/ to /opt/

##### Removed
- Subcommand "verify" download/extraction

------------
### 1.1.1
*2024/10/06*
##### Added
- Subcommand "verify" now replaces command option "-t"
- Subcommand "verify" can now test repository reachability and test releases download/extraction

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