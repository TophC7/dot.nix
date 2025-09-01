/* OLM Toggle GNOME Extension
 * Based on WARP Toggle by Vlad Krupinskii
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU
 *  General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import GObject from "gi://GObject";
import Gio from "gi://Gio";
import GLib from "gi://GLib";

import * as Main from "resource:///org/gnome/shell/ui/main.js";

import { Extension, gettext as _ } from "resource:///org/gnome/shell/extensions/extension.js";
import { QuickToggle, SystemIndicator } from "resource:///org/gnome/shell/ui/quickSettings.js";

// Use D-Bus to control systemd service
const SystemdProxy = Gio.DBusProxy.makeProxyWrapper(
    '<node>\
        <interface name="org.freedesktop.systemd1.Manager">\
            <method name="StartUnit">\
                <arg type="s" direction="in"/>\
                <arg type="s" direction="in"/>\
                <arg type="o" direction="out"/>\
            </method>\
            <method name="StopUnit">\
                <arg type="s" direction="in"/>\
                <arg type="s" direction="in"/>\
                <arg type="o" direction="out"/>\
            </method>\
            <method name="GetUnit">\
                <arg type="s" direction="in"/>\
                <arg type="o" direction="out"/>\
            </method>\
        </interface>\
    </node>'
);

let systemdProxy = null;

// Initialize D-Bus proxy
function initSystemdProxy() {
    if (!systemdProxy) {
        systemdProxy = new SystemdProxy(Gio.DBus.system, "org.freedesktop.systemd1", "/org/freedesktop/systemd1");
    }
}

// Control service via D-Bus
async function runCommand(cmd) {
    return new Promise((resolve, reject) => {
        try {
            initSystemdProxy();
            console.log(`Executing via D-Bus: ${cmd} olm.service`);

            if (cmd === "start") {
                systemdProxy.StartUnitRemote("olm.service", "replace", (result, error) => {
                    if (error) {
                        console.error("Failed to start OLM:", error);
                        reject(error);
                    } else {
                        resolve("");
                    }
                });
            } else if (cmd === "stop") {
                systemdProxy.StopUnitRemote("olm.service", "replace", (result, error) => {
                    if (error) {
                        console.error("Failed to stop OLM:", error);
                        reject(error);
                    } else {
                        resolve("");
                    }
                });
            }
        } catch (e) {
            console.error("D-Bus error:", e);
            reject(e);
        }
    });
}

// Check OLM service status without requiring privileges
async function checkStatus() {
    return new Promise((resolve, reject) => {
        try {
            const proc = new Gio.Subprocess({
                argv: ["systemctl", "is-active", "olm"],
                flags: Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE,
            });
            proc.init(null);
            proc.communicate_utf8_async(null, null, (proc, res) => {
                try {
                    let [ok, stdout, stderr] = proc.communicate_utf8_finish(res);
                    // Exit status 0 means active, non-zero means inactive
                    const isActive = proc.get_exit_status() === 0;
                    resolve(isActive);
                } catch (e) {
                    reject(e);
                }
            });
        } catch (e) {
            reject(e);
        }
    });
}

const OlmToggle = GObject.registerClass(
    class OlmToggle extends QuickToggle {
        constructor() {
            super({
                title: _("OLM Tunnel"),
                iconName: "network-vpn-symbolic",
                toggleMode: true,
                checked: false,
            });

            this._statusCheckId = null; // Store timeout ID
            this._updateStatus(); // Initial check
            this._startCheckingStatus(); // Start periodic updates

            // Monitor button state changes
            this.connect("clicked", () => {
                runCommand(this.checked ? "start" : "stop");
                if (this.checked) this._startCheckingStatus(); // Restart checking when user toggles
            });
        }

        async _updateStatus() {
            try {
                this.checked = await this._isOlmActive();
            } catch (err) {
                console.error("Error checking OLM status:", err);
            }
        }

        _startCheckingStatus() {
            if (this._statusCheckId) return; // Prevent duplicate timers
            const DELAY = 5; // Check every 5 seconds
            this._statusCheckId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, DELAY, () => {
                this._updateStatus();
                return GLib.SOURCE_CONTINUE; // Keep running
            });
        }

        _stopCheckingStatus() {
            if (this._statusCheckId) {
                GLib.source_remove(this._statusCheckId);
                this._statusCheckId = null;
            }
        }

        async _isOlmActive() {
            try {
                return await checkStatus();
            } catch (err) {
                console.error("Failed to check OLM status:", err);
                return false;
            }
        }

        destroy() {
            this._stopCheckingStatus();
            super.destroy();
        }
    }
);

const OlmIndicator = GObject.registerClass(
    class OlmIndicator extends SystemIndicator {
        constructor() {
            super();
            // Create the indicator icon
            this._indicator = this._addIndicator();
            this._indicator.iconName = "network-vpn-symbolic";
            // Create the toggle button and bind its visibility to connection state
            const toggle = new OlmToggle();
            toggle.bind_property("checked", this._indicator, "visible", GObject.BindingFlags.SYNC_CREATE);
            this.quickSettingsItems.push(toggle);
        }

        destroy() {
            // biome-ignore lint/suspicious/useIterableCallbackReturn: <explanation>
            this.quickSettingsItems.forEach((item) => item.destroy());
            super.destroy();
        }
    }
);

export default class OLMExtension extends Extension {
    enable() {
        // Check if OLM service exists
        const checkService = new Gio.Subprocess({
            argv: ["systemctl", "status", "olm"],
            flags: Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE,
        });

        try {
            checkService.init(null);
        } catch (e) {
            console.error("OLM service not found");
            Main.notifyError("OLM Toggle", "OLM service not configured on this system");
            return;
        }

        // Add the indicator to the system panel
        this._indicator = new OlmIndicator();
        Main.panel.statusArea.quickSettings.addExternalIndicator(this._indicator);
    }

    disable() {
        if (this._indicator) {
            this._indicator.destroy();
            this._indicator = null;
        }
    }
}
