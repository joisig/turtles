# Turtles Tools

This directory contains utility tools for the Turtles project.

## discover_shelly.py

A tool to scan a network for Shelly dimmers and output their information in a format compatible with the Turtles configuration.

### Requirements

- Python 3.6+
- Required packages: `aiohttp`

You can install the required packages with:
```
pip install aiohttp
```

### Usage

```
./discover_shelly.py NETWORK [--timeout TIMEOUT]
```

Where:
- `NETWORK` is the network to scan in CIDR notation (e.g., `192.168.1.0/24` or `10.0.0.0/24`)
- `--timeout` is the optional request timeout in seconds (default: 2.0)

### Example

```bash
# Scan the 192.168.1.* network for Shelly dimmers
./discover_shelly.py 192.168.1.0/24

# Scan with a longer timeout
./discover_shelly.py 192.168.1.0/24 --timeout 5.0
```

### Output

The tool outputs a list of Shelly dimmers found on the network in a format that can be directly used in the Turtles configuration:

```elixir
dimmers: [
  {"shellydimmer2",
    %{name: "shellydimmer2-485519D9BC0D", type: :shelly, zone: "", ip: "192.168.1.17"}},
  {"shellydimmer2",
    %{name: "shellydimmer2-ABCDEF123456", type: :shelly, zone: "", ip: "192.168.1.18"}},
]
```

You can copy this output directly into your configuration file.
