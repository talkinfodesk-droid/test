import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/workout_models.dart';
import '../theme/app_theme.dart';
import 'sheet_handle.dart';

/// Result of editing a set: new weight / reps, or a delete request.
class SetEdit {
  const SetEdit({this.weightKg, this.targetReps, this.delete = false});

  final double? weightKg;
  final int? targetReps;
  final bool delete;
}

/// Bottom sheet to change weight and target reps of one set.
Future<SetEdit?> showSetEditorSheet(
  BuildContext context, {
  required WorkoutSet set,
  bool canDelete = true,
}) {
  return showModalBottomSheet<SetEdit>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _SetEditorSheet(set: set, canDelete: canDelete),
  );
}

class _SetEditorSheet extends StatefulWidget {
  const _SetEditorSheet({required this.set, required this.canDelete});

  final WorkoutSet set;
  final bool canDelete;

  @override
  State<_SetEditorSheet> createState() => _SetEditorSheetState();
}

class _SetEditorSheetState extends State<_SetEditorSheet> {
  late final TextEditingController _weight;
  late final TextEditingController _reps;

  @override
  void initState() {
    super.initState();
    _weight = TextEditingController(text: formatKg(widget.set.weightKg));
    _reps = TextEditingController(text: widget.set.targetReps.toString());
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  void _save() {
    final kg = double.tryParse(_weight.text.trim());
    final reps = int.tryParse(_reps.text.trim());
    if (kg == null || kg <= 0 || reps == null || reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a weight and rep count above 0')),
      );
      return;
    }
    Navigator.of(context).pop(SetEdit(weightKg: kg, targetReps: reps));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          const SizedBox(height: 16),
          Text('Edit set ${widget.set.index}',
              style: Theme.of(context).textTheme.titleLarge),
          if (widget.set.completed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Set already logged: ${widget.set.reps} reps recorded',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Field(
                  controller: _weight,
                  label: 'Weight',
                  suffix: 'kg',
                  decimal: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  controller: _reps,
                  label: 'Target reps',
                  suffix: 'reps',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _save,
            child: const Text('Save'),
          ),
          if (widget.canDelete) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.red),
              onPressed: () =>
                  Navigator.of(context).pop(const SetEdit(delete: true)),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove set'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.suffix,
    this.decimal = false,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
        ),
      ],
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
