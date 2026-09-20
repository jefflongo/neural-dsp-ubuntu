# Nerual DSP on Ubuntu

This is a guide to use Neural DSP on Ubuntu using Wine.

1. Run the script `sudo ./ndsp.sh`, optionally setting `WINEPREFIX` first, to set up Wine.
1. Install [iLok Manager](https://www.ilok.com/#!home) and your [Neural DSP](https://neuraldsp.com/downloads) plugin.
    - You may have to use the [legacy Windows 7 64-bit iLok Manager installer](https://www.ilok.com/#!resource/legacy) to get a successful install.
1. Activate your license
1. Run the Neural DSP plugin as follows:

```bash
PIPEWIRE_LATENCY=$BUFFER_SIZE/$SAMPLE_RATE pw-jack wine /path/to/plugin.exe
```
