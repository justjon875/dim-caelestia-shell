pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Audio")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Output
        SliderRow {
            Layout.fillWidth: true
            first: true
            icon: Icons.getVolumeIcon(Audio.volume, Audio.muted)
            label: qsTr("Output")
            valueLabel: Math.round(value * 100) + "%"
            value: Audio.volume
            enabled: !Audio.muted
            onMoved: v => Audio.setVolume(v)
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Muted")
            checked: Audio.muted
            onToggled: Audio.setStreamMuted(Audio.sink, checked)
        }

        AudioDeviceList {
            nodes: Audio.sinks
            currentId: Audio.sink?.id ?? -1
            iconName: "speaker"
            placeholderIcon: "speaker"
            placeholderText: qsTr("No output devices")
            onSelected: node => Audio.setAudioSink(node)
        }

        // Input
        SliderRow {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            first: true
            icon: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
            label: qsTr("Input")
            valueLabel: Math.round(value * 100) + "%"
            value: Audio.sourceVolume
            enabled: !Audio.sourceMuted
            onMoved: v => Audio.setSourceVolume(v)
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Muted")
            checked: Audio.sourceMuted
            onToggled: Audio.setStreamMuted(Audio.source, checked)
        }

        AudioDeviceList {
            nodes: Audio.sources
            currentId: Audio.source?.id ?? -1
            iconName: "mic"
            placeholderIcon: "mic_off"
            placeholderText: qsTr("No input devices")
            onSelected: node => Audio.setAudioSource(node)
        }

        // Per-app volumes
        ConnectedRect {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            implicitHeight: appLayout.implicitHeight + appLayout.anchors.margins * 2
            first: true
            last: true

            StateLayer {
                onClicked: root.nState.openSubPage(1)
            }

            RowLayout {
                id: appLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "tune"
                    font: Tokens.font.icon.medium
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("App volumes")
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Audio.streams.length === 0 ? qsTr("No apps playing audio") : Audio.streams.length === 1 ? qsTr("1 app playing audio") : qsTr("%1 apps playing audio").arg(Audio.streams.length)
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                        animate: true
                    }
                }

                MaterialIcon {
                    text: "chevron_right"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.icon.medium
                }
            }
        }

        // Sound effects
        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            text: qsTr("Sound effects")
            font: Tokens.font.body.small
            color: Colours.palette.m3primary
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Enable sound effects")
            checked: GlobalConfig.audio.sounds.enabled
            onToggled: GlobalConfig.audio.sounds.enabled = checked
        }
        
        SliderRow {
            Layout.fillWidth: true
            icon: "volume_up"
            label: qsTr("SFX Volume")
            valueLabel: Math.round(value * 100) + "%"
            value: GlobalConfig.audio.sounds.sfxVolume
            enabled: GlobalConfig.audio.sounds.enabled
            onMoved: v => GlobalConfig.audio.sounds.sfxVolume = v
            onInteraction: v => Audio.playEffectTick()
        }

        SliderRow {
            Layout.fillWidth: true
            icon: "notifications"
            label: qsTr("Notification Volume")
            valueLabel: Math.round(value * 100) + "%"
            value: GlobalConfig.audio.sounds.notificationVolume
            enabled: GlobalConfig.audio.sounds.enabled
            onMoved: v => GlobalConfig.audio.sounds.notificationVolume = v
            onInteraction: v => Audio.playNotification()
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Camera click")
            checked: GlobalConfig.audio.sounds.cameraClick
            enabled: GlobalConfig.audio.sounds.enabled
            onToggled: GlobalConfig.audio.sounds.cameraClick = checked
        }
        
        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Charging started")
            checked: GlobalConfig.audio.sounds.chargingStarted
            enabled: GlobalConfig.audio.sounds.enabled
            onToggled: GlobalConfig.audio.sounds.chargingStarted = checked
        }
        
        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Volume tick")
            checked: GlobalConfig.audio.sounds.effectTick
            enabled: GlobalConfig.audio.sounds.enabled
            onToggled: GlobalConfig.audio.sounds.effectTick = checked
        }
        
        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Screen lock")
            checked: GlobalConfig.audio.sounds.lock
            enabled: GlobalConfig.audio.sounds.enabled
            onToggled: GlobalConfig.audio.sounds.lock = checked
        }
        
        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Screen unlock")
            checked: GlobalConfig.audio.sounds.unlock
            enabled: GlobalConfig.audio.sounds.enabled
            onToggled: GlobalConfig.audio.sounds.unlock = checked
        }
        
        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Low battery")
            checked: GlobalConfig.audio.sounds.lowBattery
            enabled: GlobalConfig.audio.sounds.enabled
            onToggled: GlobalConfig.audio.sounds.lowBattery = checked
        }
        
        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: qsTr("Screen record")
            checked: GlobalConfig.audio.sounds.screenRecord
            enabled: GlobalConfig.audio.sounds.enabled
            onToggled: GlobalConfig.audio.sounds.screenRecord = checked
        }
    }
}
