# Anon Installation Script

## Description
This repository contains a script for installing the Anon Relay on a Debian-based Linux system. The script automates the process of adding the Anon repository, installing the Anon package, and configuring the Anon Relay with user-defined settings.

## Installation
To install the Anon Relay, run the following command in your terminal:
```bash
sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ATOR-Development/anon-install/main/install.sh)"
```

## Usage
Once installed, the Anon Relay can be configured with user-defined settings. Follow the prompts provided by the script to specify your desired nickname, contact information, bandwidth settings, ORPort, and MyFamily fingerprints.

## Example
This command installs the Anon Relay on your Debian-based Linux system. It prompts you to enter the desired nickname for the Anon Relay, contact information, comma-separated fingerprints for your relay's family (which can be skipped), BandwidthRate in Mbit (which can be skipped), BandwidthBurst in Mbit (which can be skipped), and ORPort. Here's an example of the output you might see:

```bash
sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ATOR-Development/anon-install/main/install.sh)"
```
...
```mathematics
Enter your desired nickname for the Anon Relay (1-19 characters, only [a-zA-Z0-9] and no spaces): MyRelayNickname
Enter your contact information for the Anon Relay: Email <email AT example DOT com>
Enter comma-separated fingerprints for your relay's family (leave empty to skip): 6TE606BE5CB537A93E2CD0F2F5AJ0EA4C8B42FDB,0313A82A4CE6F9C4C1451099F91A1424BAC714M0
Enter BandwidthRate in Mbit (leave empty to skip): 80
Enter BandwidthBurst in Mbit (leave empty to skip): 100
Enter ORPOrt [Default: 9001]: 9002
Anon installation completed successfully.
```
## Dependencies
* curl
* sudo
* wget
* apt-get

## Contributing
Contributions to this script are welcome! If you'd like to contribute, please fork the repository, make your changes, and submit a pull request.

## License
This script is licensed under the GPL-3.0 licence.

## Contact
For questions or feedback, please contact the ATOR Development team at team@ator.io

## External Resources
[ATOR Website](https://ator.io)<br>
[Anon Education and Documentation](https://educ.ator.io)<br>
[ATOR-Development/ator-protocol GitHub Repository](https://github.com/ATOR-Development/ator-protocol)
