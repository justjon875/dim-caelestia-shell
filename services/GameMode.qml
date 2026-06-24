pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.services

Singleton {
    id: root

    property alias enabled: props.enabled

    function setDynamicConfs(): void {
        const gameModeConfig = GlobalConfig.utilities.gameMode;
        let options = {};
        if (gameModeConfig.disableHyprlandAnimations) options["animations:enabled"] = 0;
        if (gameModeConfig.disableHyprlandShadows) options["decoration:shadow:enabled"] = 0;
        if (gameModeConfig.disableHyprlandBlur) options["decoration:blur:enabled"] = 0;
        if (gameModeConfig.disableHyprlandGaps) {
            options["general:gaps_in"] = 0;
            options["general:gaps_out"] = 0;
            options["general:border_size"] = 1;
            options["decoration:rounding"] = 0;
        }
        options["general:allow_tearing"] = 1;
        
        if (gameModeConfig.disableWindowTransparency) {
            options["decoration:active_opacity"] = 1;
            options["decoration:inactive_opacity"] = 1;
            options["decoration:fullscreen_opacity"] = 1;
        }

        Hypr.extras.applyOptions(options);

        if (gameModeConfig.disableWindowTransparency) {
            if (Hypr.usingLua) {
                Hypr.extras.batchMessage([`eval hl.window_rule({ match = { class = ".*" }, opaque = true })`]);
            } else {
                Hypr.extras.batchMessage([`keyword windowrulev2 opaque, class:.*`]);
            }
        }
    }

    onEnabledChanged: {
        if (enabled) {
            setDynamicConfs();
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Game mode enabled"), qsTr("Disabled Hyprland animations, blur, gaps and shadows"), "gamepad");
        } else {
            Hypr.extras.message("reload");
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Game mode disabled"), qsTr("Hyprland settings restored"), "gamepad");
        }
    }

    PersistentProperties {
        id: props

        property bool enabled: Hypr.options["animations:enabled"] === 0 // qmllint disable missing-property

        reloadableId: "gameMode"
    }

    Connections {
        function onConfigReloaded(): void {
            if (props.enabled)
                root.setDynamicConfs();
        }

        target: Hypr
    }

    IpcHandler {
        function isEnabled(): bool {
            return props.enabled;
        }

        function toggle(): void {
            props.enabled = !props.enabled;
        }

        function enable(): void {
            props.enabled = true;
        }

        function disable(): void {
            props.enabled = false;
        }

        target: "gameMode"
    }
}
