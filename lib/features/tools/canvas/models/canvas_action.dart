import 'canvas_layer.dart';
import 'paint_stroke.dart';

/// Sealed class hierarchy for undoable canvas actions.
sealed class CanvasAction {
  const CanvasAction();

  Map<String, dynamic> toJson();

  static CanvasAction fromJson(Map<String, dynamic> json) {
    return switch (json['type'] as String) {
      'addStroke' => AddStrokeAction._fromJson(json),
      'addLayer' => AddLayerAction._fromJson(json),
      'removeLayer' => RemoveLayerAction._fromJson(json),
      'duplicateLayer' => DuplicateLayerAction._fromJson(json),
      'reorderLayer' => ReorderLayerAction._fromJson(json),
      'setLayerVisibility' => SetLayerVisibilityAction._fromJson(json),
      'setLayerOpacity' => SetLayerOpacityAction._fromJson(json),
      'setLayerBlendMode' => SetLayerBlendModeAction._fromJson(json),
      'renameLayer' => RenameLayerAction._fromJson(json),
      'clearLayer' => ClearLayerAction._fromJson(json),
      _ => throw ArgumentError('Unknown action type: ${json['type']}'),
    };
  }
}

class AddStrokeAction extends CanvasAction {
  final String layerId;
  final PaintStroke stroke;
  const AddStrokeAction({required this.layerId, required this.stroke});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'addStroke',
        'layerId': layerId,
        'stroke': stroke.toJson(),
      };

  static AddStrokeAction _fromJson(Map<String, dynamic> json) =>
      AddStrokeAction(
        layerId: json['layerId'] as String,
        stroke: PaintStroke.fromJson(json['stroke'] as Map<String, dynamic>),
      );
}

class RemoveLayerAction extends CanvasAction {
  final CanvasLayer removedLayer;
  final int index;
  const RemoveLayerAction({required this.removedLayer, required this.index});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'removeLayer',
        'removedLayer': removedLayer.toJson(),
        'index': index,
      };

  static RemoveLayerAction _fromJson(Map<String, dynamic> json) =>
      RemoveLayerAction(
        removedLayer:
            CanvasLayer.fromJson(json['removedLayer'] as Map<String, dynamic>),
        index: json['index'] as int,
      );
}

class AddLayerAction extends CanvasAction {
  final CanvasLayer layer;
  const AddLayerAction({required this.layer});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'addLayer',
        'layer': layer.toJson(),
      };

  static AddLayerAction _fromJson(Map<String, dynamic> json) => AddLayerAction(
        layer: CanvasLayer.fromJson(json['layer'] as Map<String, dynamic>),
      );
}

class ReorderLayerAction extends CanvasAction {
  final int oldIndex;
  final int newIndex;
  const ReorderLayerAction({required this.oldIndex, required this.newIndex});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'reorderLayer',
        'oldIndex': oldIndex,
        'newIndex': newIndex,
      };

  static ReorderLayerAction _fromJson(Map<String, dynamic> json) =>
      ReorderLayerAction(
        oldIndex: json['oldIndex'] as int,
        newIndex: json['newIndex'] as int,
      );
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

  @override
  Map<String, dynamic> toJson() => {
        'type': 'setLayerVisibility',
        'layerId': layerId,
        'oldVisible': oldVisible,
        'newVisible': newVisible,
      };

  static SetLayerVisibilityAction _fromJson(Map<String, dynamic> json) =>
      SetLayerVisibilityAction(
        layerId: json['layerId'] as String,
        oldVisible: json['oldVisible'] as bool,
        newVisible: json['newVisible'] as bool,
      );
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

  @override
  Map<String, dynamic> toJson() => {
        'type': 'setLayerOpacity',
        'layerId': layerId,
        'oldOpacity': oldOpacity,
        'newOpacity': newOpacity,
      };

  static SetLayerOpacityAction _fromJson(Map<String, dynamic> json) =>
      SetLayerOpacityAction(
        layerId: json['layerId'] as String,
        oldOpacity: (json['oldOpacity'] as num).toDouble(),
        newOpacity: (json['newOpacity'] as num).toDouble(),
      );
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

  @override
  Map<String, dynamic> toJson() => {
        'type': 'setLayerBlendMode',
        'layerId': layerId,
        'oldMode': oldMode.name,
        'newMode': newMode.name,
      };

  static SetLayerBlendModeAction _fromJson(Map<String, dynamic> json) =>
      SetLayerBlendModeAction(
        layerId: json['layerId'] as String,
        oldMode: CanvasBlendMode.values.firstWhere(
          (m) => m.name == json['oldMode'],
          orElse: () => CanvasBlendMode.normal,
        ),
        newMode: CanvasBlendMode.values.firstWhere(
          (m) => m.name == json['newMode'],
          orElse: () => CanvasBlendMode.normal,
        ),
      );
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

  @override
  Map<String, dynamic> toJson() => {
        'type': 'renameLayer',
        'layerId': layerId,
        'oldName': oldName,
        'newName': newName,
      };

  static RenameLayerAction _fromJson(Map<String, dynamic> json) =>
      RenameLayerAction(
        layerId: json['layerId'] as String,
        oldName: json['oldName'] as String,
        newName: json['newName'] as String,
      );
}

class ClearLayerAction extends CanvasAction {
  final String layerId;
  final List<PaintStroke> removedStrokes;
  const ClearLayerAction({
    required this.layerId,
    required this.removedStrokes,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'clearLayer',
        'layerId': layerId,
        'removedStrokes': removedStrokes.map((s) => s.toJson()).toList(),
      };

  static ClearLayerAction _fromJson(Map<String, dynamic> json) =>
      ClearLayerAction(
        layerId: json['layerId'] as String,
        removedStrokes: (json['removedStrokes'] as List)
            .map((j) => PaintStroke.fromJson(j as Map<String, dynamic>))
            .toList(),
      );
}

class DuplicateLayerAction extends CanvasAction {
  final CanvasLayer duplicatedLayer;
  final int insertIndex;
  const DuplicateLayerAction({
    required this.duplicatedLayer,
    required this.insertIndex,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'duplicateLayer',
        'duplicatedLayer': duplicatedLayer.toJson(),
        'insertIndex': insertIndex,
      };

  static DuplicateLayerAction _fromJson(Map<String, dynamic> json) =>
      DuplicateLayerAction(
        duplicatedLayer: CanvasLayer.fromJson(
            json['duplicatedLayer'] as Map<String, dynamic>),
        insertIndex: json['insertIndex'] as int,
      );
}
