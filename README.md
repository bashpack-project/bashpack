# Bashpack

The Bashpack CLI is a versatile and user-friendly script manager designed to manage scripts on any Linux distro and use them as regular commands. It simplifies script management, security, and automation, making your administrative tasks more efficient.

Anyone can self-host its own subcommands repositories, and even its own CLI repository.


## Features

- **Script Management**: Easily install, update, and remove scripts as subcommands.
- **Automation**: Automate routine tasks to save time and reduce human error.
- **Security**: Enhance the security of your Linux systems with minimal effort.
- **User-Friendly**: Accessible to both novice and experienced users.


## Quick Start

To manage your Bashpack installation, copy/paste the following command blocks into your Linux terminal.

### Install

```sh
curl -sL https://raw.githubusercontent.com/bashpack-project/bashpack/main/bashpack.sh -o bashpack.sh \
 && chmod +x bashpack.sh \
 && sudo ./bashpack.sh -i \
 && rm bashpack.sh
```

### Update

```sh
sudo bp -u
```

### Uninstall

```sh
sudo bp --self-delete
```

### Usage

```sh
bp --help
```

### Subcommand management

Install a subcommand from the repositories
```sh
sudo bp --get <subcommand>
```

Remove a subcommand
```sh
sudo bp --delete <subcommand>
```

List available remotes and installed subcommands 
```sh
sudo bp --list
```

## Configuration

Bashpack uses a configuration file located at `/etc/bashpack/bashpack.conf`. It is created and maintained automatically, but you can customize it according to your needs.

## Logs

Bashpack maintains logs in `/var/log/bashpack`. You can view the logs using the following command:

```sh
sudo bp --logs
```


## FAQ

- **POSIX Compatibility**: Bashpack is POSIX-compliant, meaning it can be installed on any POSIX system. It was first written in [Bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell)), but is now written in [Bourne shell](https://en.wikipedia.org/wiki/Bourne_shell). That being said, every specific distro software support needs to be added one by one in the subcommands.
- **Root Access**: Root/sudo access is required for installation and most operations.
- **Automatic Updates**: Bashpack can automatically update itself.
- **Repositories**: Multiple repositories exist; for production usage, only the main one should be used.


## License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/bashpack-project/bashpack/blob/main/LICENSE.md) file for details.


## Links

- [Homepage](https://bashpack-project.github.io/)
- [Main Repository](https://github.com/bashpack-project/bashpack)