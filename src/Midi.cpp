#include "Midi.h"

static const int MAX_POLL_SIZE = 2048;

MidiDevice::MidiDevice(QQuickItem * parent) :
    QQuickItem(parent),
    m_deviceIndex(-1),
    m_midiin() {
    reload();
}

MidiDevice::~MidiDevice() {
    m_midiin.closePort();
}

QStringList MidiDevice::deviceList() {
    return m_deviceList;
}

int MidiDevice::deviceIndex() {
    return m_deviceIndex;
}

void MidiDevice::setDeviceIndex(int idx) {
    // TODO: Catch exceptions or something?
    m_midiin.closePort();
    m_midiin.openPort(idx, "Radiance Input");
    m_deviceIndex = idx;
    emit deviceIndexChanged(m_deviceIndex);
}

void MidiDevice::reload() {
    // TODO: Catch exceptions or something?
    poll();

    m_deviceList.clear();
    unsigned int count = m_midiin.getPortCount();
    for (unsigned int i = 0; i < count; i++) {
        m_deviceList << QString(m_midiin.getPortName(i).c_str());
    }

    m_midiin.closePort();
    if (m_deviceIndex >= 0 && m_deviceIndex < count)
        m_midiin.openPort(m_deviceIndex);
    else
        m_deviceIndex = -1;

    emit deviceListChanged(m_deviceList);
    emit deviceIndexChanged(m_deviceIndex);

}

void MidiDevice::poll() {
    std::vector<unsigned char> msg;
    for (int i = 0; i < MAX_POLL_SIZE; i++) {
        double timestamp = m_midiin.getMessage(&msg); 
        if (!msg.size())
            break;
        unsigned char msg_type = msg[0];
        if (msg_type >= 0x80 && msg_type <= 0x8F && msg.size() >= 3) {
            emit noteOffEvent(msg_type & 0xF, msg[1], msg[2]);
        } else if (msg_type >= 0x90 && msg_type <= 0x9F && msg.size() >= 3) {
            emit noteOnEvent(msg_type & 0xF, msg[1], msg[2]);
        } else if (msg_type >= 0xC0 && msg_type <= 0xCF && msg.size() >= 3) {
            emit controlChangeEvent(msg_type & 0xF, msg[1], msg[2]);
        }
    }
}
