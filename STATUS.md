# Jelly Star: hardware and feature status

Tested on hardware with LineageOS 23.2 built from this tree. Keep this file up to date when
something is tested or fixed.

## Working

| Area | Feature | Notes |
|---|---|---|
| Display | Screen, touch, backlight | |
| Display | Auto-brightness | Light sensor drives the backlight |
| Display | Auto-rotate | |
| Buttons | Power, volume up/down | |
| Buttons | Capacitive back / home / recents | Haptic feedback via `cap_touch.kl`; declared as hardware keys, so no on-screen navigation by default and LineageOS's Settings > System > Buttons (long-press/double-tap actions, navbar toggle) is available |
| Buttons | Red shortcut key | Settings > System > Red button: flashlight, back light, camera, or pass to apps (e.g. Key Mapper). Flashlight and back light also work with the screen off |
| Audio | Speaker, microphone | |
| Audio | Headphone jack (wired headset) | Detected and used for audio. On the test unit it was not detected for a while (on stock too), later it worked with an AUX headset: most likely the plug or headset |
| Audio | FM radio | Tuning works with a wired headset as antenna (tested 2026-10-27). |
| Audio | Bluetooth media audio (A2DP), aptX | Tested with EPOS ADAPT 660 |
| Audio | Bluetooth headset microphone (HFP) | Works in calls/VoIP; voice recorder apps use the phone mic (normal Android behaviour) |
| Connectivity | Wi-Fi 2.4 and 5 GHz | 802.11ac |
| Connectivity | Wi-Fi hotspot, USB tethering, Bluetooth tethering | Hotspot also tested over 4G mobile data |
| Connectivity | Bluetooth | Factory MAC address kept |
| Connectivity | NFC | Reads bank cards (Metrodroid) and works as a card (an NFC gym check-in app); TMS chip, AOSP NFC stack |
| Connectivity | USB file transfer (MTP) | |
| Connectivity | GPS | |
| Camera | Rear (12 MP) and front (8 MP) photo | |
| Camera | 1080p video recording | Hardware H.264 encoder, audio recorded |
| Media | 1080p video playback | Hardware decoder (`c2.mtk.avc.decoder`), smooth; HEVC and VP9 hardware decoders also present |
| Camera | Torch / flash | Both LEDs work; torch uses the cold LED, like stock |
| Sensors | Accelerometer, gyroscope, magnetometer, light, proximity, step counter | |
| Security | Fingerprint | Enroll and unlock |
| Security | File-based encryption, SELinux enforcing | With a PIN, user storage stays locked after reboot until the PIN is entered |
| Lights | Front RGB LED | Any colour, per-app notification colours, battery colours (charging / charged / low), hardware blinking (slow, fast, steady). Settings > Display > Lights |
| Lights | Back LED | Quick Settings tile "Back light" with a brightness slider; pulses for notifications, breathes while charging (screen off), flashes for incoming calls. Toggle broadcast for key remappers |
| Lights | IR blaster | |
| Power | Charging, battery reporting | Battery usage estimates use stock's power profile (2000 mAh, measured component currents) |
| Power | Charge limit | Settings > Battery > Charge limit: pauses charging at the chosen level (50–95 %), resumes 5 % below; the phone runs from the charger meanwhile |
| Power | Charging while powered off | Power key boots from the charging screen |
| Power | Standby / deep sleep | About 0.6 %/hour overnight (100 % → 94 % in 10 hours) |
| Modem | Firmware, IMEI, network search | Emergency-only camping without a SIM; Danish emergency number list loads |
| Telephony | Calls, SMS, 4G mobile data | Tested with Lycamobile on Telia's network (238-20). This network does not allow VoLTE for the SIM (it reports no IMS voice support), so calls use 2G. The modem reports this MVNO as roaming, so data needs "Roaming" enabled for the SIM |
| Telephony | VoLTE (HD voice over 4G) | Tested with 3 Denmark (238-06): IMS registers over LTE and calls stay on 4G with HD audio. Uses MediaTek's stock `ImsService`. Offered for every SIM (CarrierConfig overlay); it registers wherever the network allows VoLTE for the SIM (not Lycamobile on Telia). Some carriers only allow VoLTE on phones they have approved |
| Telephony | Speakerphone | |
| Telephony | Foreign SIMs | Tested with a Faroese Telecom SIM (288-01) roaming on TDC: calls and SMS work. VoLTE does not register while roaming (TDC reports VoLTE support, the modem does not attempt IMS), most likely no VoLTE roaming between the two carriers. Data uses LineageOS's worldwide APN list |
| Install | First install from stock, following the README | Tested 2026-10-16 with the public release files: stock V01.00.04 → flash `boot`, `vendor_boot`, `dtbo`, `vbmeta` with fastboot → Lineage Recovery → format data → `adb sideload` → setup screen. The phone's bootloader was already unlocked, so the unlock confirmation itself was not re-tested |
| Install | A/B OTA updates, `adb sideload` updates | Release-key signed builds via `sign-build.sh` |
| Install | Back to stock with SP Flash Tool | Works (Download Only, stock V01.00.04 with blank `misc` and `metadata`). USB timeouts during writing can need a few retries; reconnect in download mode each time |
| Apps | microG | LineageOS's built-in signature spoofing for the official microG apps: install microG Services and Companion as normal apps, Self-Check passes. No special build needed |
| Apps | Public transport and gym check-in | Rejsekort's Rejsebillet app (Danish public transport) and an NFC gym check-in app work. Tested with microG installed and Magisk's DenyList hiding root from them |
| Apps | Root (Magisk) | Patch this build's `boot.img` in the Magisk app and flash it to the active slot (`fastboot flash boot`); after each update use "Install to inactive slot" before rebooting |

## Not working / not supported

| Feature | Reason |
|---|---|
| Play Integrity | No integrity verdict at all (NO_INTEGRITY, even Basic fails), measured with microG and with root hidden from microG by Magisk's DenyList; Device and Strong integrity are not possible. The bootloader has to stay unlocked, and this MediaTek bootloader cannot be relocked with custom signing keys. Apps that require Play Integrity (some banking and payment apps, Google Wallet tap-to-pay) will not work; apps that don't use it are unaffected. This build does not and will not spoof attestation. |
| Face unlock | Stock face unlock is part of Unihertz's modified framework; the vendor only has AOSP's placeholder face HAL. Hidden in Settings. |
| 5G | Not supported by the hardware: the Helio G99 has a 4G modem. |
| Factory sensor test (`*#*#3377#*#*`) | Stock-only app. |
| Stock Unihertz extras | Agui apps, LED belt widget, power management tweaks: replaced by this tree's own Lights app or dropped. |

## Not tested yet

| Feature | Needs |
|---|---|
| MMS | Lycamobile DK has no MMS settings in LineageOS's or stock's APN list, and Lyca's generic MMS settings entered by hand did not work either; to be tested with 3 Denmark, whose MMS settings are included. Carriers limit MMS size (300 KB by default), so larger videos are refused |
| Wi-Fi calling | In progress. MediaTek's Wi-Fi offload service (inside `ImsService`) runs and reports Wi-Fi to the vendor ePDG daemon (`epdg_wod`); stock disables Wi-Fi calling at device level (`config_device_wfc_ims_available`). Being tested with that enabled on 3 Denmark |
| Video calling (ViLTE) | Libraries are shipped; on 3 Denmark no video button appears, most likely because 3 does not offer it. Needs a carrier with ViLTE |
| Emergency calls | Not to be tested by calling; number list verified |
| microSD card | A card in the SIM tray |
| USB OTG (host mode) | USB-C adapter with a stick or keyboard |

