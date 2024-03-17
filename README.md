auto eject external drive after inactivity (macOS)

Using Macbook connected to external usb drives it is one of common use cases. Drive could be connected directly or through usb hub / display with hub. 
Quite often it is forgotten to eject the drive(s) correctly before grabbing macbook on a walk to the sofa. This can lead to data corruption and other issues.

This script safely ejects drives that contain `volumes` after `timeout` seconds of user and Time Machine inactivity.

# Bash script

- [usb-auto-eject.sh](scripts/usb-auto-eject.bash)

Variables:

- Timeout in seconds

```bash
timeout=900
```

- Volumes to eject

```bash
volumes=(
    "/Volumes/volume01" 
    "/Volumes/volume02"
)
```

# launchd plist

- [com.github.agraqqa.usb-auto-eject.plist](launchagent/com.github.agraqqa.usb-auto-eject.plist)

# To do

- [ ] log rotation
- [ ] ansible playbook to install and configure on localhost

# Install

```bash
git clone https://github.com/agraqqa/usb-auto-eject.git
sudo cp usb-auto-eject/scripts/usb-auto-eject.bash /usr/local/bin/
sudo chmod +x /usr/local/bin/usb-auto-eject.bash
cp launchagent/com.github.agraqqa.usb-auto-eject.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.github.agraqqa.usb-auto-eject.plist
```

Kickstart if needed:

```bash
launchctl kickstart -k gui/$(id -u)/com.github.agraqqa.usb-auto-eject
```

Load/unload the agent if need to disable/enable it without removing the files:

```bash
launchctl load ~/Library/LaunchAgents/com.github.agraqqa.usb-auto-eject.plist
launchctl unload ~/Library/LaunchAgents/com.github.agraqqa.usb-auto-eject.plist
```

# Logs

App logs could be found in `Console` app under "Log Reports" -> "usb-auto-eject" or just:

```bash
tail -f ~/Library/Logs/usb-auto-eject-daemon/usb-auto-eject-$(date +%Y%m%d).log
```

# Uninstall

Bootout the agent and remove the files:

```bash
launchctl bootout gui/$(id -u) com.github.agraqqa.usb-auto-eject
rm ~/Library/LaunchAgents/com.github.agraqqa.usb-auto-eject.plist
sudo rm /usr/local/bin/usb-auto-eject.bash
```

# License

MIT

# Author

[agraqqa](github.com/agraqqa)
