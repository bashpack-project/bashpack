> [!CAUTION]
> **This repository is intended for development and testing purposes.**\
> Stable releases are available at https://github.com/bashpack-project/bashpack

# Bashpack unstable & dev

**Install unstable**
```javascript
curl -sL https://raw.githubusercontent.com/bashpack-project/bashpack-unstable/main/bashpack.sh -o bashpack.sh \
 && chmod +x bashpack.sh \
 && sudo ./bashpack.sh -u \
 && rm bashpack.sh
```

**Install dev**
```javascript
curl -sL https://raw.githubusercontent.com/bashpack-project/bashpack-dev/main/bashpack.sh -o bashpack.sh \
 && chmod +x bashpack.sh \
 && sudo ./bashpack.sh -u \
 && rm bashpack.sh
```

**Switch from main to unstable repository**
```javascript
sudo sed -i 's/main/unstable/g' /etc/bashpack/bashpack_config \
 && sudo bp -u
```

**Switch from unstable to dev repository**
```javascript
sudo sed -i 's/unstable/dev/g' /etc/bashpack/bashpack_config \
 && sudo bp -u
```

**Switch from dev to unstable repository**
```javascript
sudo sed -i 's/dev/unstable/g' /etc/bashpack/bashpack_config \
 && sudo bp -u
```

**Uninstall**
```javascript
sudo bp --self-delete
```

**Usage**
```javascript
bp --help
```

<br>
