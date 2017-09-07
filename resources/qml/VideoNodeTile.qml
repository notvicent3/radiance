import QtQuick 2.3
import QtQuick.Layouts 1.2
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import radiance 1.0

FocusScope {
    id: tile;
    property var model;
    property var videoNode;
    property var inputHeights;
    property int gridX;
    property int gridY;

    property int padding: 5;
    property int blockWidth: 100;
    property int blockHeight: 170;
    property bool selected: false;

    property var lastX;
    property var lastY;
    property var dragCC;
    property var dragging;

    function sum(l) {
        var result = 0;
        for(var i=0; i<l.length; i++) result += l[i];
        return result;
    }

    function regrid() {
        x = parent.width - (gridX + 1) * (blockWidth + padding);
        y = (gridY + 0.5 * (inputHeights[0] - 1)) * (blockHeight + padding);
        height = (blockHeight + padding) * (sum(inputHeights) - (inputHeights[inputHeights.length - 1] - 1)) - padding;
    }

    onGridXChanged: {
        if (!dragging) regrid();
    }

    onGridYChanged: {
        if (!dragging) regrid();
    }

    onInputHeightsChanged: {
        if (!dragging) regrid();
    }

    width: blockWidth;

    Drag.keys: [ "videonode" ]
    Drag.hotSpot: Qt.point(width / 2, height / 2)
    Drag.active: dragArea.drag.active;

    function dragLift() {
        var ccs = parent.selectedConnectedComponents();
        var i;
        for (i=0; i<ccs.length; i++) {
            if (ccs[i].tiles.indexOf(tile) >= 0) break;
        }
        if (i == ccs.length) return; // Drag object was not found in selection??
        dragCC = ccs[i];
        lastX = x;
        lastY = y;
        for (var i=0; i<dragCC.tiles.length; i++) {
            dragCC.tiles[i].dragging = true;
            dragCC.tiles[i].z = 1;
        }
    }

    function dragDrop() {
        for (var i=0; i<dragCC.tiles.length; i++) {
            dragCC.tiles[i].dragging = false;
            dragCC.tiles[i].z = 0;
        }

        var t = Drag.target;
        var me = videoNode;
        if (t !== null
         && dragCC.vertices.indexOf(t.fromNode) < 0
         && dragCC.vertices.indexOf(t.toNode) < 0) {
            var fn = t.fromNode;
            var tn = t.toNode;
            var ti = t.toInput;

            // Step 1. Rewire the nodes surrounding drag source
            // to cut out the dragged blocks

            for (var i=0; i<dragCC.inputEdges.length; i++) {
                var e = dragCC.inputEdges[i];
                model.removeEdge(e.fromVertex, e.toVertex, e.toInput);
            }
            for (var i=0; i<dragCC.outputEdges.length; i++) {
                var e = dragCC.outputEdges[i];
                model.removeEdge(e.fromVertex, e.toVertex, e.toInput);
            }

            // Step 2. Stitch those back together
            if (dragCC.inputEdges.length >= 1) {
                for (var i=0; i<dragCC.outputEdges.length; i++) {
                    var f = dragCC.inputEdges[0];
                    var t = dragCC.outputEdges[i];
                    model.addEdge(f.fromVertex, t.toVertex, t.toInput);
                }
            }

            // Step 3. Cut the connection at the drag target
            if (fn !== null && tn !== null) model.removeEdge(fn, tn, ti);

            // Step 4. Connect up the dragged blocks at the drag target
            if (fn !== null) {
                for (var i=0; i<dragCC.inputPorts.length; i++) {
                    var t = dragCC.inputPorts[i];
                    model.addEdge(fn, t.vertex, t.input);
                    break; // TODO hook this up to every input?
                }
            }
            if (tn !== null) {
                model.addEdge(dragCC.outputNode, tn, ti);
            }
            model.flush();
        }
        for (var i=0; i<dragCC.tiles.length; i++) {
            dragCC.tiles[i].regrid();
        }
    }

    function deleteSelected() {
        for (;;) {
            var ccs = parent.selectedConnectedComponents();
            if (ccs.length == 0) break;
            var deleteCC = ccs[0];

            // Step 1. Delete nodes
            for (var i=0; i<deleteCC.vertices.length; i++) {
                var e = deleteCC.vertices[i];
                model.removeVideoNode(e);
            }

            // Step 2. Stitch the surrounding blocks back together
            if (deleteCC.inputEdges.length >= 1) {
                for (var i=0; i<deleteCC.outputEdges.length; i++) {
                    var f = deleteCC.inputEdges[0];
                    var t = deleteCC.outputEdges[i];
                    model.addEdge(f.fromVertex, t.toVertex, t.toInput);
                }
            }
        }
        model.flush();
    }

    MouseArea {
        id: dragArea;
        z: -1;
        anchors.fill: parent;

        onClicked: {
            if (mouse.button == Qt.LeftButton) {
                tile.forceActiveFocus();
                var tiles = [tile];
                if (mouse.modifiers & Qt.ShiftModifier && tile.parent.parent.lastClickedTile) {
                    tiles = tile.parent.tilesBetween(tile.parent.parent.lastClickedTile, tile);
                    if (tiles.length == 0) tiles = [tile];
                }
                if (mouse.modifiers & Qt.ControlModifier) {
                    tile.parent.toggleSelection(tiles);
                } else if (mouse.modifiers & Qt.AltModifier) {
                    tile.parent.removeFromSelection(tiles);
                } else {
                    tile.parent.select(tiles);
                }
                tile.parent.parent.lastClickedTile = tile;
            }
        }

        drag.onActiveChanged: {
            tile.parent.ensureSelected(tile);
            if (drag.active) {
                dragLift();
            } else {
                dragDrop();
            }
        }

        drag.target: tile;
    }

    RadianceTile {
        anchors.fill: parent;
        selected: parent.selected;
        focus: true;
    }

    Behavior on x {
        enabled: !dragging
        NumberAnimation {
            easing {
                type: Easing.InOutQuad
                amplitude: 1.0
                period: 0.5
            }
            duration: 500
        }
    }
    Behavior on y {
        enabled: !dragging
        NumberAnimation {
            easing {
                type: Easing.InOutQuad
                amplitude: 1.0
                period: 0.5
            }
            duration: 500
        }
    }
    Behavior on z {
        enabled: !dragging
        NumberAnimation {
            easing {
                type: Easing.InOutQuad
                amplitude: 1.0
                period: 0.5
            }
            duration: 500
        }
    }
    Behavior on height {
        enabled: !dragging
        NumberAnimation {
            easing {
                type: Easing.InOutQuad
                amplitude: 1.0
                period: 0.5
            }
            duration: 500
        }
    }

    onXChanged: {
        if (Drag.active) {
            var deltaX = x - lastX;
            for(var i = 0; i < dragCC.tiles.length; ++i) {
                if (dragCC.tiles[i] != this) {
                    dragCC.tiles[i].x += deltaX;
                }
            }
            lastX = x;
        }
    }

    onYChanged: {
        if (Drag.active) {
            var deltaY = y - lastY;
            for(var i = 0; i < dragCC.tiles.length; ++i) {
                if (dragCC.tiles[i] != this) {
                    dragCC.tiles[i].y += deltaY;
                }
            }
            lastY = y;
        }
    }

    Keys.onPressed: {
        if (event.key == Qt.Key_Delete) {
            deleteSelected();
        }
    }
}
