import { bind, Variable } from "astal";
import { App, Astal, Gtk, Gdk } from "astal/gtk4";
import GLib from "gi://GLib";
import { Volume, Workspaces, Launcher } from "./components";

const time = Variable<string>("").poll(1000, () => GLib.DateTime.new_now_local().format("%H:%M - %A %e.")!);

function Left() {
    return (
        <box>
            <Launcher />
            <Gtk.Separator />
            <Workspaces />
        </box>
    );
}

function Center() {
    return (
        <box>
            {/* <Time /> */}
        </box>
    );
}

function Right() {
    return <></>;
}


export default function Bar(gdkmonitor: Gdk.Monitor) {
    const { TOP, LEFT, RIGHT } = Astal.WindowAnchor;

    return (
        <window
            visible
            cssName="window"
            gdkmonitor={gdkmonitor}
            exclusivity={Astal.Exclusivity.EXCLUSIVE}
            anchor={TOP | LEFT | RIGHT}
            application={App}
        >
            <centerbox cssName="centerbox" cssClasses={["container"]}>
                <box spacing={6} halign={Gtk.Align.CENTER}>
                    <Launcher />
                    <Workspaces />
                </box>

                <box spacing={6} halign={Gtk.Align.CENTER}>
                    <box>
                        <menubutton>
                            <label label={time()} />
                            <popover>
                                <Gtk.Calendar canTarget={false} canFocus={false} />
                            </popover>
                        </menubutton>
                    </box>
                </box>

                <box spacing={6} halign={Gtk.Align.END}>
                    <Volume />
                </box>
            </centerbox>
        </window>
    );
}