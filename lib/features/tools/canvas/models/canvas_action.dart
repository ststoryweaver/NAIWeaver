import 'canvas_layer.dart';
import 'paint_stroke.dart';

/// Sealed class hierarchy for undoable canvas actions.
sealed class CanvasAction {
  const CanvasAction();
}

class AddStrokeAction extends CanvasAction {
  final String layerId;
  final PaintStroke stroke;
  const AddStrokeAction({required this.layerId, required this.stroke});
}

class RemoveLayerAction extends CanvasAction {
  final CanvasLayer removedLayer;
  final int index;
  const RemoveLayerAction({required this.removedLayer, required this.index});
}

class AddLayerAction extends CanvasAction {
  final CanvasLayer layer;
  const AddLayerAction({required this.layer});
}

class ReorderLayerAction extends CanvasAction {
  final int oldIndex;
  final int newIndex;
  const ReorderLayerAction({required this.oldIndex, required this.newIndex});
}

class SetLayerVisibilityAction extends CanvasAction {
  final String layerId;
  final bool oldVisible;
  final bool newVisible;
  const SetLayerVisibilityAction({
    required this.layerId,
    required this.oldVisible,
    required this.newVisible,
  });
}

class SetLayerOpacityAction extends CanvasAction {
  final String layerId;
  final double oldOpacity;
  final double newOpacity;
  const SetLayerOpacityAction({
    required this.layerId,
    required this.oldOpacity,
    required this.newOpacity,
  });
}

class SetLayerBlendModeAction extends CanvasAction {
  final String layerId;
  final CanvasBlendMode oldMode;
  final CanvasBlendMode newMode;
  const SetLayerBlendModeAction({
    required this.layerId,
    required this.oldMode,
    required this.newMode,
  });
}

class RenameLayerAction extends CanvasAction {
  final String layerId;
  final String oldName;
  final String newName;
  const RenameLayerAction({
    required this.layerId,
    required this.oldName,
    required this.newName,
  });
}

class ClearLayerAction extends CanvasAction {
  final String layerId;
  final List<PaintStroke> removedStrokes;
  const ClearLayerAction({
    required this.layerId,
    required this.removedStrokes,
  });
}

class DuplicateLayerAction extends CanvasAction {
  final CanvasLayer duplicatedLayer;
  final int insertIndex;
  const DuplicateLayerAction({
    required this.duplicatedLayer,
    required this.insertIndex,
  });
}
