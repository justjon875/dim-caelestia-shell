#pragma once

#include "configobject.hpp"

namespace caelestia::config {

class AudioSounds : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, enabled, true)
    CONFIG_GLOBAL_PROPERTY(bool, cameraClick, true)
    CONFIG_GLOBAL_PROPERTY(bool, chargingStarted, true)
    CONFIG_GLOBAL_PROPERTY(bool, effectTick, true)
    CONFIG_GLOBAL_PROPERTY(bool, lock, true)
    CONFIG_GLOBAL_PROPERTY(bool, unlock, true)
    CONFIG_GLOBAL_PROPERTY(bool, lowBattery, true)
    CONFIG_GLOBAL_PROPERTY(bool, screenRecord, true)

public:
    explicit AudioSounds(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class AudioConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_SUBOBJECT(AudioSounds, sounds)

public:
    explicit AudioConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_sounds(new AudioSounds(this)) {}
};

} // namespace caelestia::config
