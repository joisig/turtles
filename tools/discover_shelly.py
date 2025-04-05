#!/usr/bin/env python3
"""
discover_shelly.py - Tool to scan a network for Shelly dimmers.

This script scans all IP addresses in a private IP range (e.g., 192.168.1.* or 10.0.0.*) 
and identifies Shelly dimmers by making HTTP requests to each IP.
"""

import argparse
import asyncio
import aiohttp
import ipaddress
import json
import re
from typing import List, Dict, Tuple, Optional


async def fetch_settings(session: aiohttp.ClientSession, ip: str, timeout: float = 2.0) -> Optional[Dict]:
    """
    Fetch settings from a potential Shelly device.
    
    Args:
        session: aiohttp client session
        ip: IP address to check
        timeout: Request timeout in seconds
    
    Returns:
        Dictionary of settings if device is a Shelly, None otherwise
    """
    url = f"http://{ip}/settings"
    try:
        async with session.get(url, timeout=timeout) as response:
            if response.status == 200:
                return await response.json()
    except (aiohttp.ClientError, asyncio.TimeoutError, json.JSONDecodeError):
        pass
    return None


def is_shelly_dimmer(settings: Dict) -> bool:
    """
    Check if the settings belong to a Shelly dimmer.
    
    Args:
        settings: Device settings
    
    Returns:
        True if device is a Shelly dimmer, False otherwise
    """
    if not settings or "device" not in settings:
        return False
    
    # Check if it's a Shelly device
    device_type = settings.get("device", {}).get("type", "")
    
    # Check specifically for dimmer types
    return device_type.startswith("SHDM")


def format_dimmer_output(settings: Dict, ip: str) -> Tuple[str, Dict]:
    """
    Format dimmer output as required.
    
    Args:
        settings: Device settings
        ip: IP address of the device
    
    Returns:
        Tuple of (hostname_key, device_info_dict)
    """
    device_info = settings.get("device", {})
    hostname = device_info.get("hostname", "").lower()
    
    # Extract the first part of the hostname (before any dash)
    hostname_key = re.sub(r'-.*$', '', hostname)
    if not hostname_key:
        hostname_key = f"shelly_{ip.replace('.', '_')}"
    
    # Create the device info dictionary
    device_dict = {
        "name": hostname,
        "type": ":shelly",
        "zone": "",  # Zone would need to be configured separately
        "ip": ip
    }
    
    return hostname_key, device_dict


async def scan_ip(ip: str, session: aiohttp.ClientSession, timeout: float) -> Optional[Tuple[str, Dict]]:
    """
    Scan a single IP address for a Shelly dimmer.
    
    Args:
        ip: IP address to scan
        session: aiohttp client session
        timeout: Request timeout in seconds
    
    Returns:
        Tuple of (hostname_key, device_info_dict) if a Shelly dimmer is found, None otherwise
    """
    settings = await fetch_settings(session, ip, timeout)
    if settings and is_shelly_dimmer(settings):
        return format_dimmer_output(settings, ip)
    return None


async def scan_network(network: str, timeout: float = 2.0) -> List[Tuple[str, Dict]]:
    """
    Scan a network for Shelly dimmers.
    
    Args:
        network: Network to scan (e.g., 192.168.1.0/24)
        timeout: Request timeout in seconds
    
    Returns:
        List of tuples (hostname_key, device_info_dict) for each Shelly dimmer found
    """
    dimmers = []
    
    # Parse the network
    try:
        net = ipaddress.IPv4Network(network)
    except ValueError:
        print(f"Invalid network: {network}")
        return dimmers
    
    # Create a semaphore to limit concurrent requests
    semaphore = asyncio.Semaphore(50)
    
    async def scan_with_semaphore(ip):
        async with semaphore:
            return await scan_ip(str(ip), session, timeout)
    
    # Scan all IPs in the network
    async with aiohttp.ClientSession() as session:
        tasks = [scan_with_semaphore(ip) for ip in net.hosts()]
        results = await asyncio.gather(*tasks)
        
        # Filter out None results
        dimmers = [result for result in results if result is not None]
    
    return dimmers


def format_output(dimmers: List[Tuple[str, Dict]]) -> str:
    """
    Format the output as required.
    
    Args:
        dimmers: List of tuples (hostname_key, device_info_dict)
    
    Returns:
        Formatted string
    """
    if not dimmers:
        return "  dimmers: []"
    
    lines = ["  dimmers: ["]
    
    for hostname_key, device_dict in dimmers:
        line = f'    {{"{hostname_key}",\n      %{{name: "{device_dict["name"]}", type: {device_dict["type"]}, zone: "{device_dict["zone"]}", ip: "{device_dict["ip"]}"}}}},'
        lines.append(line)
    
    lines[-1] = lines[-1].rstrip(',')  # Remove trailing comma from the last item
    lines.append("  ]")
    
    return "\n".join(lines)


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description='Discover Shelly dimmers on a network')
    parser.add_argument('network', help='Network to scan (e.g., 192.168.1.0/24)')
    parser.add_argument('--timeout', type=float, default=2.0, help='Request timeout in seconds')
    return parser.parse_args()


async def main():
    """Main function."""
    args = parse_args()
    
    print(f"Scanning network {args.network} for Shelly dimmers...")
    dimmers = await scan_network(args.network, args.timeout)
    
    print(f"Found {len(dimmers)} Shelly dimmers")
    print(format_output(dimmers))


if __name__ == "__main__":
    asyncio.run(main())
