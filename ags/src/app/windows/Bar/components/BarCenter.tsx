import { App, Astal, Gtk, Gdk } from "astal/gtk4";
import { GLib, Variable } from "astal";

function Time({ format = "%H:%M - %A %e." }) {
    const time = Variable<string>("").poll(1000, () => GLib.DateTime.new_now_local().format(format)!);

    return <label cssName="Time" onDestroy={() => time.drop()} label={time()} />;
}

export default function BarCenter() {
    return (
        <box>
            <Time />
        </box>
    );
}
