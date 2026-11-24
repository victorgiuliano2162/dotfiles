#!/usr/bin/python3
import json
import os
import signal
import subprocess
import sys

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, GLib, Gtk

PID_FILE = f"/tmp/waybar-audio-menu-{os.getuid()}.pid"

CSS = b"""
window {
    background-color: #1e1e2e;
    border: 1px solid #313244;
    border-radius: 8px;
}
button {
    background-image: none;
    box-shadow: none;
    text-shadow: none;
    border: none;
    outline: none;
}
.container {
    padding: 10px 12px;
}
.section-title {
    color: #89b4fa;
    font-family: "0xProto Nerd Font Mono", monospace;
    font-size: 12px;
    font-weight: bold;
    margin-top: 6px;
    margin-bottom: 4px;
}
.device-btn {
    background-color: transparent;
    color: #cdd6f4;
    border-radius: 6px;
    padding: 6px 8px;
    font-family: "0xProto Nerd Font Mono", monospace;
    font-size: 12px;
}
.device-btn:hover {
    background-color: #313244;
    color: #89b4fa;
}
.device-btn.active {
    background-color: #313244;
    color: #a6e3a1;
    font-weight: bold;
}
.mute-btn {
    background-color: #313244;
    color: #cdd6f4;
    border-radius: 6px;
    padding: 4px 8px;
    font-family: "0xProto Nerd Font Mono", monospace;
    font-size: 12px;
}
.mute-btn:hover {
    background-color: #45475a;
}
.mute-btn.muted {
    color: #f38ba8;
}
.adv-btn {
    background-color: #181825;
    color: #a6adc8;
    border: 1px solid #313244;
    border-radius: 6px;
    padding: 6px 8px;
    margin-top: 8px;
    font-family: "0xProto Nerd Font Mono", monospace;
    font-size: 12px;
}
.adv-btn:hover {
    background-color: #313244;
    color: #cdd6f4;
}
scale {
    color: #cdd6f4;
    font-family: "0xProto Nerd Font Mono", monospace;
    font-size: 12px;
}
scale trough {
    background-color: #313244;
    background-image: none;
    border: none;
    border-radius: 4px;
    min-height: 6px;
}
scale highlight {
    background-color: #89b4fa;
    background-image: none;
    border: none;
    border-radius: 4px;
}
scale slider {
    background-color: #cdd6f4;
    background-image: none;
    box-shadow: none;
    border: none;
    border-radius: 50%;
    min-width: 14px;
    min-height: 14px;
    margin: -4px 0;
}
separator {
    background-color: #313244;
    margin: 6px 0;
}
"""


def run_cmd(cmd):
    return subprocess.check_output(cmd, text=True).strip()


def get_pactl_json(kind):
    return json.loads(run_cmd(["pactl", "-f", "json", "list", kind]))


def extract_volume_pct(node):
    vol = node.get("volume", {})
    for ch in vol.values():
        pct_str = ch.get("value_percent", "0%").rstrip("%")
        try:
            return int(pct_str)
        except ValueError:
            pass
    return 0


def toggle_existing_instance():
    if os.path.exists(PID_FILE):
        try:
            with open(PID_FILE) as f:
                old_pid = int(f.read().strip())
            if old_pid != os.getpid():
                os.kill(old_pid, signal.SIGTERM)
                os.remove(PID_FILE)
                return True
        except (OSError, ValueError):
            pass
    with open(PID_FILE, "w") as f:
        f.write(str(os.getpid()))
    return False


def cleanup_pid():
    try:
        if os.path.exists(PID_FILE):
            with open(PID_FILE) as f:
                if f.read().strip() == str(os.getpid()):
                    os.remove(PID_FILE)
    except OSError:
        pass


class AudioMenu(Gtk.Window):
    def __init__(self):
        super().__init__(title="Controle de Áudio")
        self.set_decorated(False)
        self.set_resizable(False)
        self.set_default_size(320, -1)
        self.set_keep_above(True)

        self.ready_to_auto_close = False
        self.add_events(Gdk.EventMask.ENTER_NOTIFY_MASK)
        self.connect("enter-notify-event", self.on_enter_notify)
        self.connect("focus-out-event", self.on_focus_out)
        self.connect("key-press-event", self.on_key_press)
        self.connect("destroy", lambda *_: Gtk.main_quit())
        GLib.timeout_add(1000, self.enable_auto_close)

        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

        self.box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        self.box.get_style_context().add_class("container")
        self.add(self.box)

        self.build_ui()
        self.show_all()

    def enable_auto_close(self):
        self.ready_to_auto_close = True
        return False

    def on_enter_notify(self, _widget, _event):
        self.ready_to_auto_close = True
        return False

    def on_focus_out(self, _widget, _event):
        if self.ready_to_auto_close:
            Gtk.main_quit()
        return False

    def on_key_press(self, _widget, event):
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()
            return True
        return False

    def clear_box(self):
        for child in self.box.get_children():
            self.box.remove(child)

    def build_ui(self):
        self.clear_box()

        default_sink = run_cmd(["pactl", "get-default-sink"])
        default_source = run_cmd(["pactl", "get-default-source"])
        sinks = get_pactl_json("sinks")
        sources = [
            s for s in get_pactl_json("sources") if not s["name"].endswith(".monitor")
        ]

        cur_sink = next((s for s in sinks if s["name"] == default_sink), None)
        cur_source = next((s for s in sources if s["name"] == default_source), None)

        # --- Volume de Saída ---
        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        title = Gtk.Label(label="Volume de Saída", xalign=0)
        title.get_style_context().add_class("section-title")
        close_btn = Gtk.Button(label="✕")
        close_btn.get_style_context().add_class("mute-btn")
        close_btn.connect("clicked", lambda *_: Gtk.main_quit())
        header.pack_start(title, True, True, 0)
        header.pack_end(close_btn, False, False, 0)
        self.box.pack_start(header, False, False, 0)
        if cur_sink:
            self.add_volume_row(
                is_sink=True,
                node_name=cur_sink["name"],
                volume=extract_volume_pct(cur_sink),
                muted=cur_sink.get("mute", False),
            )

        # --- Saídas de Som ---
        self.add_section_title("Saída Padrão")
        for s in sinks:
            is_active = s["name"] == default_sink
            label = f"{'✓ ' if is_active else '  '}{s.get('description', s['name'])}"
            btn = self.make_left_button(label, "device-btn", is_active)
            btn.connect("clicked", self.on_select_sink, s["name"])
            self.box.pack_start(btn, False, False, 0)

        self.box.pack_start(Gtk.Separator(), False, False, 2)

        # --- Microfone ---
        self.add_section_title("Microfone")
        if cur_source:
            self.add_volume_row(
                is_sink=False,
                node_name=cur_source["name"],
                volume=extract_volume_pct(cur_source),
                muted=cur_source.get("mute", False),
            )

        for src in sources:
            is_active = src["name"] == default_source
            label = f"{'✓ ' if is_active else '  '}{src.get('description', src['name'])}"
            btn = self.make_left_button(label, "device-btn", is_active)
            btn.connect("clicked", self.on_select_source, src["name"])
            self.box.pack_start(btn, False, False, 0)

        # --- Avançado ---
        adv_btn = Gtk.Button(label="⚙  Abrir Pavucontrol (avançado)")
        adv_btn.get_style_context().add_class("adv-btn")
        adv_btn.connect("clicked", self.on_open_pavucontrol)
        self.box.pack_start(adv_btn, False, False, 0)

        self.box.show_all()

    def add_section_title(self, text):
        lbl = Gtk.Label(label=text, xalign=0)
        lbl.get_style_context().add_class("section-title")
        self.box.pack_start(lbl, False, False, 0)

    def make_left_button(self, text, css_class, active=False):
        btn = Gtk.Button()
        lbl = Gtk.Label(label=text, xalign=0)
        lbl.set_ellipsize(3)  # Pango.EllipsizeMode.END
        lbl.set_max_width_chars(34)
        btn.add(lbl)
        ctx = btn.get_style_context()
        ctx.add_class(css_class)
        if active:
            ctx.add_class("active")
        return btn

    def add_volume_row(self, is_sink, node_name, volume, muted):
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)

        scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 2)
        scale.set_value(min(volume, 100))
        scale.set_draw_value(True)
        scale.set_value_pos(Gtk.PositionType.RIGHT)
        scale.set_hexpand(True)
        scale.connect("value-changed", self.on_volume_changed, is_sink, node_name)

        mute_lbl = "Mudo" if muted else ("" if is_sink else "")
        mute_btn = Gtk.Button(label=mute_lbl)
        ctx = mute_btn.get_style_context()
        ctx.add_class("mute-btn")
        if muted:
            ctx.add_class("muted")
        mute_btn.connect("clicked", self.on_toggle_mute, is_sink, node_name)

        row.pack_start(scale, True, True, 0)
        row.pack_start(mute_btn, False, False, 0)
        self.box.pack_start(row, False, False, 2)

    def on_volume_changed(self, scale, is_sink, node_name):
        val = int(scale.get_value())
        cmd = "set-sink-volume" if is_sink else "set-source-volume"
        subprocess.Popen(["pactl", cmd, node_name, f"{val}%"])

    def on_toggle_mute(self, _btn, is_sink, node_name):
        cmd = "set-sink-mute" if is_sink else "set-source-mute"
        subprocess.run(["pactl", cmd, node_name, "toggle"], check=False)
        self.build_ui()

    def on_select_sink(self, _btn, sink_name):
        subprocess.run(["pactl", "set-default-sink", sink_name], check=False)
        for si in get_pactl_json("sink-inputs"):
            subprocess.run(
                ["pactl", "move-sink-input", str(si["index"]), sink_name], check=False
            )
        self.build_ui()

    def on_select_source(self, _btn, source_name):
        subprocess.run(["pactl", "set-default-source", source_name], check=False)
        for so in get_pactl_json("source-outputs"):
            subprocess.run(
                ["pactl", "move-source-output", str(so["index"]), source_name],
                check=False,
            )
        self.build_ui()

    def on_open_pavucontrol(self, _btn):
        subprocess.Popen(["pavucontrol"])
        Gtk.main_quit()


if __name__ == "__main__":
    GLib.set_prgname("waybar-audio-menu")
    if toggle_existing_instance():
        sys.exit(0)
    try:
        AudioMenu()
        Gtk.main()
    finally:
        cleanup_pid()
