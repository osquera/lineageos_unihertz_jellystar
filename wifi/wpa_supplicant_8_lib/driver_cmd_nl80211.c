/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */
/*
 * driver_cmd_nl80211.c - private wpa_supplicant DRIVER commands for MediaTek gen4m (mindone, 06.09.2026).
 * Scheme like lib_driver_cmd_qcwcn/bcmdhd: START/STOP via interface flags, MACADDR via SIOCGIFHWADDR,
 * everything else (SETSUSPENDMODE, COUNTRY, SETBAND, RXFILTER-*, BTCOEXSCAN-*, P2P_*) as a string into the driver
 * via ioctl SIOCDEVPRIVATE+1 (android_wifi_priv_cmd), which gen4m parses in priv_support_driver_cmd().
 */
#include "includes.h"
#include <sys/types.h>
#include <fcntl.h>
#include <net/if.h>
#include <sys/ioctl.h>

#include "common.h"
#include "linux_ioctl.h"
#include "driver_nl80211.h"
#include "wpa_supplicant_i.h"
#include "config.h"
#ifdef ANDROID
#include "android_drv.h"
#endif
#ifndef MAX_DRV_CMD_SIZE
#define MAX_DRV_CMD_SIZE 248
#endif

typedef struct android_wifi_priv_cmd {
	char *buf;
	int used_len;
	int total_len;
} android_wifi_priv_cmd;

static void notify_country_change(void *ctx, const char *cmd)
{
	union wpa_event_data event;

	if (os_strncasecmp(cmd, "COUNTRY", 7) != 0 && os_strncasecmp(cmd, "SETBAND", 7) != 0)
		return;
	os_memset(&event, 0, sizeof(event));
	event.channel_list_changed.initiator = REGDOM_SET_BY_USER;
	if (os_strncasecmp(cmd, "COUNTRY", 7) == 0) {
		event.channel_list_changed.type = REGDOM_TYPE_COUNTRY;
		if (os_strlen(cmd) > 9) {
			event.channel_list_changed.alpha2[0] = cmd[8];
			event.channel_list_changed.alpha2[1] = cmd[9];
		}
	} else {
		event.channel_list_changed.type = REGDOM_TYPE_UNKNOWN;
	}
	wpa_supplicant_event(ctx, EVENT_CHANNEL_LIST_CHANGED, &event);
}

int wpa_driver_nl80211_driver_cmd(void *priv, char *cmd, char *buf, size_t buf_len)
{
	struct i802_bss *bss = priv;
	struct wpa_driver_nl80211_data *drv = bss->drv;
	struct wpa_driver_nl80211_data *driver;
	struct ifreq ifr;
	android_wifi_priv_cmd priv_cmd;
	int ret = 0;

	if (os_strcasecmp(cmd, "START") == 0) {
		dl_list_for_each(driver, &drv->global->interfaces, struct wpa_driver_nl80211_data, list) {
			linux_set_iface_flags(drv->global->ioctl_sock, driver->first_bss->ifname, 1);
			wpa_msg(drv->ctx, MSG_INFO, WPA_EVENT_DRIVER_STATE "STARTED");
		}
		return 0;
	}
	if (os_strcasecmp(cmd, "MACADDR") == 0) {
		u8 macaddr[ETH_ALEN] = {};

		ret = linux_get_ifhwaddr(drv->global->ioctl_sock, bss->ifname, macaddr);
		if (!ret)
			ret = os_snprintf(buf, buf_len, "Macaddr = " MACSTR "\n", MAC2STR(macaddr));
		return ret;
	}

	/* Private driver command: the string is copied into buf, the driver writes the reply back into it. */
	if (os_strlen(cmd) + 1 > buf_len)
		return -1;
	os_memset(&ifr, 0, sizeof(ifr));
	os_memset(&priv_cmd, 0, sizeof(priv_cmd));
	os_memcpy(buf, cmd, os_strlen(cmd) + 1);
	os_strlcpy(ifr.ifr_name, bss->ifname, IFNAMSIZ);
	priv_cmd.buf = buf;
	priv_cmd.used_len = buf_len;
	priv_cmd.total_len = buf_len;
	ifr.ifr_data = &priv_cmd;

	ret = ioctl(drv->global->ioctl_sock, SIOCDEVPRIVATE + 1, &ifr);
	if (ret < 0) {
		wpa_printf(MSG_ERROR, "%s: private command '%s' failed: %s", __func__, cmd, strerror(errno));
		return ret;
	}
	ret = 0;
	if (os_strcasecmp(cmd, "LINKSPEED") == 0 || os_strcasecmp(cmd, "RSSI") == 0 ||
	    os_strcasecmp(cmd, "GETBAND") == 0)
		ret = os_strlen(buf);
	else if (os_strcasecmp(cmd, "STOP") == 0) {
		dl_list_for_each(driver, &drv->global->interfaces, struct wpa_driver_nl80211_data, list) {
			linux_set_iface_flags(drv->global->ioctl_sock, driver->first_bss->ifname, 0);
			wpa_msg(drv->ctx, MSG_INFO, WPA_EVENT_DRIVER_STATE "STOPPED");
		}
	} else
		wpa_printf(MSG_DEBUG, "%s: '%s' → '%s'", __func__, cmd, buf);
	notify_country_change(drv->ctx, cmd);
	return ret;
}

int wpa_driver_set_p2p_noa(void *priv, u8 count, int start, int duration)
{
	char buf[MAX_DRV_CMD_SIZE];

	os_memset(buf, 0, sizeof(buf));
	os_snprintf(buf, sizeof(buf), "P2P_SET_NOA %d %d %d", count, start, duration);
	return wpa_driver_nl80211_driver_cmd(priv, buf, buf, sizeof(buf));
}

int wpa_driver_get_p2p_noa(void *priv, u8 *buf, size_t len)
{
	/* gen4m does not report NoA via this path */
	return 0;
}

int wpa_driver_set_p2p_ps(void *priv, int legacy_ps, int opp_ps, int ctwindow)
{
	char buf[MAX_DRV_CMD_SIZE];

	os_memset(buf, 0, sizeof(buf));
	os_snprintf(buf, sizeof(buf), "P2P_SET_PS %d %d %d", legacy_ps, opp_ps, ctwindow);
	return wpa_driver_nl80211_driver_cmd(priv, buf, buf, sizeof(buf));
}

int wpa_driver_set_ap_wps_p2p_ie(void *priv, const struct wpabuf *beacon,
				 const struct wpabuf *proberesp, const struct wpabuf *assocresp)
{
	/* IEs are set via the standard nl80211 path */
	return 0;
}
