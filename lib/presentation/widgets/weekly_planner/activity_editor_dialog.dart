import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/weekly_plan.dart';

class ActivityEditorDialog extends StatefulWidget {
  final LessonActivity? activity;
  final DateTime targetDate;
  final Function(LessonActivity, DateTime) onSave;

  const ActivityEditorDialog({
    super.key,
    this.activity,
    required this.targetDate,
    required this.onSave,
  });

  @override
  State<ActivityEditorDialog> createState() => _ActivityEditorDialogState();
}

class _ActivityEditorDialogState extends State<ActivityEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _objectivesController = TextEditingController();
  final _materialsController = TextEditingController();
  final _tagsController = TextEditingController();

  ActivityType _selectedType = ActivityType.lesson;
  SubjectCategory _selectedSubject = SubjectCategory.english;
  Grade _selectedGrade = Grade.grade1;
  Duration _selectedDuration = const Duration(minutes: 45);
  DateTime _selectedDate = DateTime.now();
  Color _selectedColor = const Color(0xFF6B73FF);

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.targetDate;

    if (widget.activity != null) {
      _populateFields(widget.activity!);
    }
  }

  void _populateFields(LessonActivity activity) {
    _titleController.text = activity.title;
    _descriptionController.text = activity.description;
    _objectivesController.text = activity.objectives ?? '';
    _materialsController.text = activity.materials ?? '';
    _tagsController.text = activity.tags.join(', ');

    _selectedType = activity.type;
    _selectedSubject = activity.subject;
    _selectedGrade = activity.grade;
    _selectedDuration = activity.duration;
    _selectedColor = Color(activity.colorCode ?? 0xFF6B73FF);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _objectivesController.dispose();
    _materialsController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.activity != null;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(isEditing),
            const SizedBox(height: 16),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildTitleField(),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
                    const SizedBox(height: 16),
                    _buildTypeAndSubjectRow(),
                    const SizedBox(height: 16),
                    _buildGradeAndDurationRow(),
                    const SizedBox(height: 16),
                    _buildDateField(),
                    const SizedBox(height: 16),
                    _buildColorPicker(),
                    const SizedBox(height: 16),
                    _buildObjectivesField(),
                    const SizedBox(height: 16),
                    _buildMaterialsField(),
                    const SizedBox(height: 16),
                    _buildTagsField(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildActions(isEditing),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEditing) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _selectedColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          isEditing ? 'Edit Activity' : 'New Activity',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Activity Title',
        hintText: 'Enter activity title',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description',
        hintText: 'Describe the activity',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a description';
        }
        return null;
      },
    );
  }

  Widget _buildTypeAndSubjectRow() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<ActivityType>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Activity Type',
              border: OutlineInputBorder(),
            ),
            items: ActivityType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getActivityTypeName(type)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedType = value;
                });
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<SubjectCategory>(
            value: _selectedSubject,
            decoration: const InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(),
            ),
            items: SubjectCategory.values.map((subject) {
              return DropdownMenuItem(
                value: subject,
                child: Text(_getSubjectName(subject)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedSubject = value;
                  _selectedColor = _getSubjectColor(value);
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGradeAndDurationRow() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<Grade>(
            value: _selectedGrade,
            decoration: const InputDecoration(
              labelText: 'Grade Level',
              border: OutlineInputBorder(),
            ),
            items: Grade.values.map((grade) {
              return DropdownMenuItem(
                value: grade,
                child: Text(_getGradeName(grade)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedGrade = value;
                });
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: _selectedDuration.inMinutes,
            decoration: const InputDecoration(
              labelText: 'Duration',
              border: OutlineInputBorder(),
            ),
            items: [15, 30, 45, 60, 90, 120].map((minutes) {
              return DropdownMenuItem(
                value: minutes,
                child: Text('$minutes minutes'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedDuration = Duration(minutes: value);
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Scheduled Date',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          _formatDate(_selectedDate),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    final colors = [
      const Color(0xFF6B73FF),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
      const Color(0xFF673AB7),
      const Color(0xFFFF5722),
      const Color(0xFF795548),
      const Color(0xFF607D8B),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: colors.map((color) {
            final isSelected = _selectedColor.value == color.value;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3,
                        )
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildObjectivesField() {
    return TextFormField(
      controller: _objectivesController,
      decoration: const InputDecoration(
        labelText: 'Learning Objectives (Optional)',
        hintText: 'What should students learn from this activity?',
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
    );
  }

  Widget _buildMaterialsField() {
    return TextFormField(
      controller: _materialsController,
      decoration: const InputDecoration(
        labelText: 'Materials Needed (Optional)',
        hintText: 'List materials and resources needed',
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
    );
  }

  Widget _buildTagsField() {
    return TextFormField(
      controller: _tagsController,
      decoration: const InputDecoration(
        labelText: 'Tags (Optional)',
        hintText: 'Enter tags separated by commas',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildActions(bool isEditing) {
    return Row(
      children: [
        if (isEditing)
          TextButton.icon(
            onPressed: _showDeleteConfirmation,
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _saveActivity,
          child: Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _saveActivity() {
    if (_formKey.currentState!.validate()) {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final activity = LessonActivity(
        id: widget.activity?.id ?? const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        type: _selectedType,
        subject: _selectedSubject,
        grade: _selectedGrade,
        duration: _selectedDuration,
        objectives: _objectivesController.text.isEmpty
            ? null
            : _objectivesController.text,
        materials: _materialsController.text.isEmpty
            ? null
            : _materialsController.text,
        tags: tags,
        colorCode: _selectedColor.value,
        createdAt: widget.activity?.createdAt ?? DateTime.now(),
        modifiedAt: widget.activity != null ? DateTime.now() : null,
      );

      widget.onSave(activity, _selectedDate);
      Navigator.of(context).pop();
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Are you sure you want to delete this activity?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close confirmation
              Navigator.of(context).pop(); // Close editor
              // Delete activity - would trigger via bloc
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getActivityTypeName(ActivityType type) {
    return type
        .toString()
        .split('.')
        .last
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        )
        .trim();
  }

  String _getSubjectName(SubjectCategory subject) {
    return subject
        .toString()
        .split('.')
        .last
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        )
        .trim();
  }

  String _getGradeName(Grade grade) {
    return grade.toString().split('.').last.replaceAll('grade', 'Grade ');
  }

  Color _getSubjectColor(SubjectCategory subject) {
    const colors = {
      SubjectCategory.math: Color(0xFF4CAF50),
      SubjectCategory.science: Color(0xFF2196F3),
      SubjectCategory.english: Color(0xFF9C27B0),
      SubjectCategory.history: Color(0xFFFF9800),
      SubjectCategory.geography: Color(0xFF8BC34A),
      SubjectCategory.art: Color(0xFFE91E63),
      SubjectCategory.music: Color(0xFF673AB7),
      SubjectCategory.physicalEducation: Color(0xFFFF5722),
      SubjectCategory.socialStudies: Color(0xFF795548),
      SubjectCategory.computerScience: Color(0xFF607D8B),
    };
    return colors[subject] ?? const Color(0xFF6B73FF);
  }
}
