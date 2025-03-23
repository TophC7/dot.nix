import { App, Astal, Gtk, Gdk } from "astal/gtk4";
import { bind, GLib, Variable } from "astal";
import Hyprland from "gi://AstalHyprland";

const time = Variable("").poll(1000, "date");

function Launcher() {
    return (
        <button cssName="barauncher">
            <image iconName={GLib.get_os_info("LOGO") || "missing-symbolic"} />
        </button>
    );
}

function Workspaces() {
    const hypr = Hyprland.get_default();

    return (
        <box cssName="Workspaces">
            {bind(hypr, "workspaces").as((wss) =>
                wss
                    .filter((ws) => !(ws.id >= -99 && ws.id <= -2)) // filter out special workspaces
                    .sort((a, b) => a.id - b.id)
                    .map((ws) => (
                        <button
                            cssName={bind(hypr, "focusedWorkspace")
                                .as((fw) => (ws === fw ? "focused" : ""))
                                .get()}
                            onClicked={() => ws.focus()}
                        >
                            {ws.id}
                        </button>
                    ))
            )}
        </box>
    );
}

export default function BarLeft() {
    return (
        <box>
            <Launcher />
            <Workspaces />
        </box>
    );
}
