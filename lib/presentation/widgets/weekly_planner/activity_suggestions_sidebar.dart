import 'package:flutter/material.dart';
import '../../../domain/entities/weekly_plan.dart';

class ActivitySuggestionsSidebar extends StatefulWidget {
  final List<ActivitySuggestion> suggestions;
  final List<LessonActivity> filteredActivities;
  final List<WeeklyPlan> templates;
  final Function(ActivitySuggestion, DateTime) onSuggestionApplied;
  final Function(WeeklyPlan) onTemplateApplied;
  final Function(SubjectCategory?, Grade?, ActivityType?) onFilterChanged;
  final Function(String) onSearchChanged;
  final Map<String, dynamic> currentFilters;

  const ActivitySuggestionsSidebar({
    super.key,
    required this.suggestions,
    required this.filteredActivities,
    required this.templates,
    required this.onSuggestionApplied,
    required this.onTemplateApplied,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.currentFilters,
  });

  @override
  State<ActivitySuggestionsSidebar> createState() =>
      _ActivitySuggestionsSidebarState();
}

class _ActivitySuggestionsSidebarState extends State<ActivitySuggestionsSidebar>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildFilters(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSuggestionsTab(),
                _buildActivitiesTab(),
                _buildTemplatesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Assistant',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Suggestions'),
              Tab(text: 'Activities'),
              Tab(text: 'Templates'),
            ],
            labelColor: Theme.of(context).colorScheme.onPrimaryContainer,
            unselectedLabelColor: Theme.of(context)
                .colorScheme
                .onPrimaryContainer
                .withOpacity(0.7),
            indicatorColor: Theme.of(context).colorScheme.onPrimaryContainer,
            indicatorSize: TabBarIndicatorSize.tab,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search activities...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    widget.onSearchChanged('');
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: widget.onSearchChanged,
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown<SubjectCategory>(
                  'Subject',
                  SubjectCategory.values,
                  widget.currentFilters['subject'] as SubjectCategory?,
                  (value) => widget.onFilterChanged(value, null, null),
                  (subject) => _getSubjectName(subject),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterDropdown<Grade>(
                  'Grade',
                  Grade.values,
                  widget.currentFilters['grade'] as Grade?,
                  (value) => widget.onFilterChanged(null, value, null),
                  (grade) => _getGradeName(grade),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildFilterDropdown<ActivityType>(
            'Type',
            ActivityType.values,
            widget.currentFilters['type'] as ActivityType?,
            (value) => widget.onFilterChanged(null, null, value),
            (type) => _getActivityTypeName(type),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>(
    String label,
    List<T> items,
    T? selectedValue,
    Function(T?) onChanged,
    String Function(T) getDisplayName,
  ) {
    return DropdownButtonFormField<T>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        DropdownMenuItem<T>(
          value: null,
          child: Text('All ${label}s'),
        ),
        ...items.map((item) => DropdownMenuItem<T>(
              value: item,
              child: Text(getDisplayName(item)),
            )),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildSuggestionsTab() {
    if (widget.suggestions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.lightbulb_outline,
        title: 'No Suggestions',
        subtitle:
            'Try adjusting your filters to see AI-generated activity suggestions.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = widget.suggestions[index];
        return _buildSuggestionCard(suggestion);
      },
    );
  }

  Widget _buildSuggestionCard(ActivitySuggestion suggestion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getSubjectColor(suggestion.subject),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(suggestion.relevanceScore * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.description,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(_getSubjectName(suggestion.subject)),
                  backgroundColor:
                      _getSubjectColor(suggestion.subject).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _getSubjectColor(suggestion.subject),
                    fontSize: 10,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 4),
                Chip(
                  label: Text(_getGradeName(suggestion.grade)),
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  labelStyle: const TextStyle(fontSize: 10),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 4),
                Chip(
                  label: Text('${suggestion.estimatedDuration.inMinutes}min'),
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  labelStyle: const TextStyle(fontSize: 10),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showApplyToDateDialog(suggestion),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add to Day'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showSuggestionDetails(suggestion),
                  icon: const Icon(Icons.info_outline),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesTab() {
    if (widget.filteredActivities.isEmpty) {
      return _buildEmptyState(
        icon: Icons.assignment_outlined,
        title: 'No Activities',
        subtitle: 'No activities match your current filters.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.filteredActivities.length,
      itemBuilder: (context, index) {
        final activity = widget.filteredActivities[index];
        return _buildActivityCard(activity);
      },
    );
  }

  Widget _buildActivityCard(LessonActivity activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _getSubjectColor(activity.subject),
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          activity.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${_getSubjectName(activity.subject)} • ${activity.duration.inMinutes}min',
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Add to Day'),
              onTap: () => _showApplyActivityDialog(activity),
            ),
            PopupMenuItem(
              child: const Text('View Details'),
              onTap: () => _showActivityDetails(activity),
            ),
          ],
        ),
        onTap: () => _showActivityDetails(activity),
      ),
    );
  }

  Widget _buildTemplatesTab() {
    if (widget.templates.isEmpty) {
      return _buildEmptyState(
        icon: Icons.library_books_outlined,
        title: 'No Templates',
        subtitle: 'Save a weekly plan as a template to see it here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.templates.length,
      itemBuilder: (context, index) {
        final template = widget.templates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplateCard(WeeklyPlan template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.library_books,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    template.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (template.templateCategory != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      template.templateCategory!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                    ),
                  ),
              ],
            ),
            if (template.description != null) ...[
              const SizedBox(height: 8),
              Text(
                template.description!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${template.allActivities.length} activities',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${template.totalWeekDuration.inHours}h total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onTemplateApplied(template),
                child: const Text('Apply Template'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showApplyToDateDialog(ActivitySuggestion suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Day'),
        content: const Text('Select which day to add this activity to:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // For now, add to today
              widget.onSuggestionApplied(suggestion, DateTime.now());
            },
            child: const Text('Add to Today'),
          ),
        ],
      ),
    );
  }

  void _showApplyActivityDialog(LessonActivity activity) {
    // Similar to suggestion dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Activity'),
        content: Text('Add "${activity.title}" to which day?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Create suggestion from activity and apply
              final suggestion = ActivitySuggestion(
                id: activity.id,
                title: activity.title,
                description: activity.description,
                type: activity.type,
                subject: activity.subject,
                grade: activity.grade,
                estimatedDuration: activity.duration,
                keywords: activity.tags,
                relevanceScore: 1.0,
                source: 'existing_activity',
              );
              widget.onSuggestionApplied(suggestion, DateTime.now());
            },
            child: const Text('Add to Today'),
          ),
        ],
      ),
    );
  }

  void _showSuggestionDetails(ActivitySuggestion suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(suggestion.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(suggestion.description),
              const SizedBox(height: 16),
              _buildDetailRow('Subject', _getSubjectName(suggestion.subject)),
              _buildDetailRow('Grade', _getGradeName(suggestion.grade)),
              _buildDetailRow('Type', _getActivityTypeName(suggestion.type)),
              _buildDetailRow('Duration',
                  '${suggestion.estimatedDuration.inMinutes} minutes'),
              _buildDetailRow(
                  'Relevance', '${(suggestion.relevanceScore * 100).toInt()}%'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showApplyToDateDialog(suggestion);
            },
            child: const Text('Add to Day'),
          ),
        ],
      ),
    );
  }

  void _showActivityDetails(LessonActivity activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activity.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(activity.description),
              const SizedBox(height: 16),
              _buildDetailRow('Subject', _getSubjectName(activity.subject)),
              _buildDetailRow('Grade', _getGradeName(activity.grade)),
              _buildDetailRow('Type', _getActivityTypeName(activity.type)),
              _buildDetailRow(
                  'Duration', '${activity.duration.inMinutes} minutes'),
              if (activity.objectives != null)
                _buildDetailRow('Objectives', activity.objectives!),
              if (activity.materials != null)
                _buildDetailRow('Materials', activity.materials!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
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
}
