# Oneline V2ray Setup

Install and setup v2ray service with one command (for VPS).

Tested on vultr Debian 11.

## Usage

```
bash < <(curl -L https://raw.githubusercontent.com/purple4pur/oneline-v2ray-setup/main/run.sh)
```

| Command | Description |
|---|---|
| `./run.sh` | Install/Update v2ray with default port (10727) |
| `./run.sh -p 10727` | Install/Update v2ray with custom port |
| `./run.sh -v` | Summarize current `config.json` |
| `./run.sh -u` | Install/update v2ray only |
| `./run.sh -h` | Get this help menu |

## Reference

<https://itlanyan.com/v2ray-tutorial/>
