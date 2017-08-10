#pragma once

#include "OpenGLWorker.h"
#include <QOpenGLTexture>
#include <QSharedPointer>
#include <QVector>
#include <QQuickWindow>
#include <QMutex>
#include "RenderTrigger.h"

// The Everpresent God Object (EGO)

class VideoNode;
class Model;
class RenderContext;
class ModelGraph;

class RenderContextOpenGLWorker : public OpenGLWorker {
    Q_OBJECT

public:
    RenderContextOpenGLWorker(RenderContext *p);
public slots:
    void initialize();
signals:
    void initialized();
protected:
    void createBlankTexture();
    void createNoiseTextures();
    RenderContext *m_p;
};

///////////////////////////////////////////////////////////////////////////////

class RenderContext : public QObject {
    Q_OBJECT

    friend class RenderContextOpenGLWorker;

public:
    RenderContext();
   ~RenderContext() override;
    int chainCount();
    QSize chainSize(int chain);
    GLuint noiseTexture(int chain);
    GLuint blankTexture();
    void makeCurrent();

public slots:
    void render(Model *m, int chain);

    // This is an annoying little hack
    // to get around QML's difficulty
    // in making a DirectConnection from
    // beforeSynchronizing to render
    void addRenderTrigger(QQuickWindow *window, Model *model, int chain);
    void removeRenderTrigger(QQuickWindow *window, Model *model, int chain);
    // In the future we can override this function so that
    // more than just QQuickWindows can trigger renders

protected slots:
    void onInitialized();

private:
    QList<int> topoSort(const ModelGraph &graph);
    bool m_initialized;
    QVector<QSharedPointer<QOpenGLTexture>> m_noiseTextures;
    QOpenGLTexture m_blankTexture;
    QList<RenderTrigger> m_renderTriggers;
    RenderContextOpenGLWorker m_openGLWorker;
};
