import { bind } from "astal";
import Wp from "gi://AstalWp";

export default function VolumeStatus() {
    const speaker = Wp.get_default()?.audio.defaultSpeaker!;

    return (
        <box
            onScroll={(_, __, dy) =>
                dy < 0 ? (speaker.volume += 0.01) : (speaker.volume += -0.01)
            }
            spacing={2}
        >
            <image iconName={bind(speaker, "volumeIcon")} />
            <label
                label={bind(speaker, "volume").as((p) => `${Math.floor(p * 100)}%`)}
            />
        </box>
    );
}