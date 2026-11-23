"""Prints the id of an available iPad simulator (newest iOS first)."""
import json
import subprocess

devices = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"]))["devices"]
for runtime in sorted((r for r in devices if ".iOS-" in r), reverse=True):
    for device in devices[runtime]:
        if device["name"].startswith("iPad"):
            print(device["udid"])
            raise SystemExit(0)
raise SystemExit("no iPad simulator found")
