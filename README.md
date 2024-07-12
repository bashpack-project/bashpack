> [!CAUTION]
> **This repository is intended for development and testing purposes.**\
> Stable releases are available at https://github.com/bashpack-project/bashpack

# Bashpack unstable & dev

### Installation

**unstable**
```javascript
curl -sL https://raw.githubusercontent.com/bashpack-project/bashpack-unstable/main/bashpack.sh -o bashpack.sh \
 && chmod +x bashpack.sh \
 && sudo ./bashpack.sh -i \
 && rm bashpack.sh
```

**dev**
```javascript
curl -sL https://raw.githubusercontent.com/bashpack-project/bashpack-dev/main/bashpack.sh -o bashpack.sh \
 && chmod +x bashpack.sh \
 && sudo ./bashpack.sh -i \
 && rm bashpack.sh
```

### Switch between repository
_To switch between repositories, you have to edit the "production" in /etc/bashpack/bashpack_config_\
**main to unstable**
```javascript
sudo sed -i 's/main/unstable/g' /etc/bashpack/bashpack_config \
 && sudo bp -u
```

**unstable to dev**
```javascript
sudo sed -i 's/unstable/dev/g' /etc/bashpack/bashpack_config \
 && sudo bp -u
```

**dev to unstable**
```javascript
sudo sed -i 's/dev/unstable/g' /etc/bashpack/bashpack_config \
 && sudo bp -u
```

### Uninstall
```javascript
sudo bp --self-delete
```

### Usage
```javascript
bp --help
```

<br>
