#include "CrossFaderUI.h"
#include "main.h"

#include <QtCore/QMutex>
#include <QtGui/QOpenGLContext>
#include <QtQuick/QSGSimpleTextureNode>
#include <QtQuick/QQuickWindow>

CrossFaderUI::CrossFaderUI()
    : m_left(0)
    , m_right(0) {
    CrossFader *c = new CrossFader(renderContext);
    connect(c, &CrossFader::parameterChanged, this, &CrossFaderUI::parameterChanged);
    m_videoNode = c;

    connect(renderContext, &RenderContext::fpsChanged, this, &VideoNodeUI::setFps);
    connect(c, &VideoNode::initialized, this, &CrossFaderUI::onInitialized, Qt::DirectConnection);
}

void CrossFaderUI::onInitialized() {
    static_cast<CrossFader*>(m_videoNode)->load();
}

qreal CrossFaderUI::parameter() {
    return static_cast<CrossFader*>(m_videoNode)->parameter();
}

VideoNodeUI *CrossFaderUI::left() {
    return m_left;
}

VideoNodeUI *CrossFaderUI::right() {
    return m_right;
}

void CrossFaderUI::setParameter(qreal value) {
    static_cast<CrossFader*>(m_videoNode)->setParameter(value);
}

void CrossFaderUI::setLeft(VideoNodeUI *value) {
    m_left = value;
    CrossFader *e = static_cast<CrossFader*>(m_videoNode);
    if(m_left == NULL) {
        e->setLeft(NULL);
    } else {
        e->setLeft(value->m_videoNode);
    }
    emit leftChanged(value);
}

void CrossFaderUI::setRight(VideoNodeUI *value) {
    m_right = value;
    CrossFader *e = static_cast<CrossFader*>(m_videoNode);
    if(m_right == NULL) {
        e->setRight(NULL);
    } else {
        e->setRight(value->m_videoNode);
    }
    emit rightChanged(value);
}
