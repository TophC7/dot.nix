
import { GLib } from "astal";

export default function Launcher() {
    return (
        <button cssName="barauncher">
            <image iconName={GLib.get_os_info("LOGO") || "missing-symbolic"} />
        </button>
    );
}