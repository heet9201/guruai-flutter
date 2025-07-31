import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/responsive_layout.dart';
import '../bloc/app_bloc.dart';
import '../bloc/app_state.dart';
import 'weekly_planner_demo.dart';

class LessonPlannerScreen extends StatefulWidget {
  const LessonPlannerScreen({super.key});

  @override
  State<LessonPlannerScreen> createState() => _LessonPlannerScreenState();
}

class _LessonPlannerScreenState extends State<LessonPlannerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        final languageCode = state is AppLoaded ? state.languageCode : 'en';

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  title: Text(_getLessonPlannerTitle(languageCode)),
                  floating: true,
                  snap: true,
                  forceElevated: innerBoxIsScrolled,
                  bottom: TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.calendar_today),
                        text: _getMyPlansLabel(languageCode),
                      ),
                      Tab(
                        icon: const Icon(Icons.add_circle_outline),
                        text: _getCreateNewLabel(languageCode),
                      ),
                      Tab(
                        icon: const Icon(Icons.library_books),
                        text: _getTemplatesLabel(languageCode),
                      ),
                      Tab(
                        icon: const Icon(Icons.calendar_view_week),
                        text: _getWeeklyPlannerLabel(languageCode),
                      ),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildMyPlansTab(context, languageCode),
                _buildCreateNewTab(context, languageCode),
                _buildTemplatesTab(context, languageCode),
                const WeeklyPlannerDemo(),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _createNewLessonPlan(context, languageCode),
            icon: const Icon(Icons.add),
            label: Text(_getCreatePlanLabel(languageCode)),
          ),
        );
      },
    );
  }

  Widget _buildMyPlansTab(BuildContext context, String languageCode) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveLayout.getHorizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Weekly overview
          _buildWeeklyOverview(context, languageCode),

          const SizedBox(height: 24),

          // Recent plans
          Text(
            _getRecentPlansTitle(languageCode),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),

          _buildRecentPlansList(context, languageCode),
        ],
      ),
    );
  }

  Widget _buildWeeklyOverview(BuildContext context, String languageCode) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_view_week,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _getThisWeekTitle(languageCode),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Week days with lessons
            ...List.generate(5, (index) {
              final dayNames = _getDayNames(languageCode);
              final subjects = ['Math', 'Science', 'English', 'History', 'Art'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        dayNames[index],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          subjects[index],
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPlansList(BuildContext context, String languageCode) {
    final samplePlans = [
      {
        'title': 'Introduction to Solar System',
        'subject': 'Science',
        'grade': 'Grade 4',
        'duration': '45 min',
        'date': '2024-01-15',
        'status': 'completed',
      },
      {
        'title': 'Fraction Operations',
        'subject': 'Math',
        'grade': 'Grade 5',
        'duration': '50 min',
        'date': '2024-01-14',
        'status': 'in_progress',
      },
      {
        'title': 'Story Writing Workshop',
        'subject': 'English',
        'grade': 'Grade 3',
        'duration': '40 min',
        'date': '2024-01-13',
        'status': 'draft',
      },
    ];

    return Column(
      children: samplePlans.map((plan) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getSubjectColor(plan['subject'] as String),
              child: Icon(
                _getSubjectIcon(plan['subject'] as String),
                color: Colors.white,
              ),
            ),
            title: Text(
              plan['title'] as String,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${plan['subject']} • ${plan['grade']} • ${plan['duration']}'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _getStatusIcon(plan['status'] as String),
                      size: 16,
                      color: _getStatusColor(plan['status'] as String),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getStatusLabel(plan['status'] as String, languageCode),
                      style: TextStyle(
                        color: _getStatusColor(plan['status'] as String),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Text(_getEditLabel(languageCode)),
                  onTap: () => _editPlan(plan),
                ),
                PopupMenuItem(
                  child: Text(_getDuplicateLabel(languageCode)),
                  onTap: () => _duplicatePlan(plan),
                ),
                PopupMenuItem(
                  child: Text(_getDeleteLabel(languageCode)),
                  onTap: () => _deletePlan(plan),
                ),
              ],
            ),
            onTap: () => _openPlan(plan),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCreateNewTab(BuildContext context, String languageCode) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveLayout.getHorizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            _getCreateNewPlanTitle(languageCode),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _getCreateNewPlanDescription(languageCode),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          _buildLessonPlanForm(context, languageCode),
        ],
      ),
    );
  }

  Widget _buildLessonPlanForm(BuildContext context, String languageCode) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getLessonDetailsTitle(languageCode),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),

            // Lesson Title
            TextFormField(
              decoration: InputDecoration(
                labelText: _getLessonTitleLabel(languageCode),
                hintText: _getLessonTitleHint(languageCode),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Subject and Grade
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: _getSubjectLabel(languageCode),
                      hintText: _getSubjectHint(languageCode),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: _getGradeLabel(languageCode),
                      hintText: _getGradeHint(languageCode),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Duration and Date
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: _getDurationLabel(languageCode),
                      hintText: _getDurationHint(languageCode),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: _getDateLabel(languageCode),
                      hintText: _getDateHint(languageCode),
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Learning Objectives
            TextFormField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: _getObjectivesLabel(languageCode),
                hintText: _getObjectivesHint(languageCode),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Materials Needed
            TextFormField(
              maxLines: 2,
              decoration: InputDecoration(
                labelText: _getMaterialsLabel(languageCode),
                hintText: _getMaterialsHint(languageCode),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _generateLessonPlan(context, languageCode),
                icon: const Icon(Icons.auto_awesome),
                label: Text(_getGeneratePlanLabel(languageCode)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesTab(BuildContext context, String languageCode) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveLayout.getHorizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            _getTemplatesTitle(languageCode),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _getTemplatesDescription(languageCode),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          _buildTemplateCategories(context, languageCode),
        ],
      ),
    );
  }

  Widget _buildTemplateCategories(BuildContext context, String languageCode) {
    final categories = [
      {
        'title': _getMathTemplatesTitle(languageCode),
        'description': _getMathTemplatesDescription(languageCode),
        'icon': Icons.calculate,
        'color': Colors.blue,
        'templates': ['Basic Arithmetic', 'Geometry', 'Algebra', 'Statistics'],
      },
      {
        'title': _getScienceTemplatesTitle(languageCode),
        'description': _getScienceTemplatesDescription(languageCode),
        'icon': Icons.science,
        'color': Colors.green,
        'templates': ['Physics', 'Chemistry', 'Biology', 'Earth Science'],
      },
      {
        'title': _getLanguageTemplatesTitle(languageCode),
        'description': _getLanguageTemplatesDescription(languageCode),
        'icon': Icons.language,
        'color': Colors.orange,
        'templates': ['Grammar', 'Reading', 'Writing', 'Speaking'],
      },
      {
        'title': _getSocialTemplatesTitle(languageCode),
        'description': _getSocialTemplatesDescription(languageCode),
        'icon': Icons.public,
        'color': Colors.purple,
        'templates': ['History', 'Geography', 'Civics', 'Culture'],
      },
    ];

    return Column(
      children: categories.map((category) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: category['color'] as Color,
              child: Icon(
                category['icon'] as IconData,
                color: Colors.white,
              ),
            ),
            title: Text(
              category['title'] as String,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            subtitle: Text(category['description'] as String),
            children: (category['templates'] as List<String>).map((template) {
              return ListTile(
                title: Text(template),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _useTemplate(template),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  // Action methods
  void _createNewLessonPlan(BuildContext context, String languageCode) {
    _tabController.animateTo(1); // Switch to Create New tab
  }

  void _generateLessonPlan(BuildContext context, String languageCode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getGeneratingPlanMessage(languageCode)),
      ),
    );
  }

  void _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      // Handle date selection
    }
  }

  void _editPlan(Map<String, dynamic> plan) {
    // Edit plan logic
  }

  void _duplicatePlan(Map<String, dynamic> plan) {
    // Duplicate plan logic
  }

  void _deletePlan(Map<String, dynamic> plan) {
    // Delete plan logic
  }

  void _openPlan(Map<String, dynamic> plan) {
    // Open plan details
  }

  void _useTemplate(String template) {
    // Use template logic
  }

  // Helper methods
  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'math':
        return Colors.blue;
      case 'science':
        return Colors.green;
      case 'english':
        return Colors.orange;
      case 'history':
        return Colors.purple;
      case 'art':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'math':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'english':
        return Icons.language;
      case 'history':
        return Icons.history_edu;
      case 'art':
        return Icons.palette;
      default:
        return Icons.book;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.play_circle;
      case 'draft':
        return Icons.edit;
      default:
        return Icons.circle;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'draft':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  List<String> _getDayNames(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return ['सोमवार', 'मंगलवार', 'बुधवार', 'गुरुवार', 'शुक्रवार'];
      case 'mr':
        return ['सोमवार', 'मंगळवार', 'बुधवार', 'गुरुवार', 'शुक्रवार'];
      case 'ta':
        return ['திங்கள்', 'செவ்வாய்', 'புதன்', 'வியாழன்', 'வெள்ளி'];
      default:
        return ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    }
  }

  // Localization methods
  String _getLessonPlannerTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'पाठ योजनाकार';
      case 'mr':
        return 'धडा योजनाकार';
      case 'ta':
        return 'பாட திட்டமிடுபவர்';
      default:
        return 'Lesson Planner';
    }
  }

  String _getMyPlansLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'मेरी योजनाएं';
      case 'mr':
        return 'माझ्या योजना';
      case 'ta':
        return 'எனது திட்டங்கள்';
      default:
        return 'My Plans';
    }
  }

  String _getCreateNewLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'नई बनाएं';
      case 'mr':
        return 'नवीन तयार करा';
      case 'ta':
        return 'புதிதாக உருவாக்கு';
      default:
        return 'Create New';
    }
  }

  String _getTemplatesLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'टेम्प्लेट';
      case 'mr':
        return 'टेम्प्लेट';
      case 'ta':
        return 'வார்ப்புருக்கள்';
      default:
        return 'Templates';
    }
  }

  String _getWeeklyPlannerLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'साप्ताहिक योजना';
      case 'mr':
        return 'साप्ताहिक योजना';
      case 'ta':
        return 'வார திட்டம்';
      case 'te':
        return 'వారపు ప్రణాళిక';
      case 'kn':
        return 'ವಾರದ ಯೋಜನೆ';
      case 'ml':
        return 'പ്രാപ്തി പദ്ധതി';
      case 'gu':
        return 'સાપ્તાહિક યોજના';
      case 'bn':
        return 'সাপ্তাহিক পরিকল্পনা';
      case 'pa':
        return 'ਹਫਤਾਵਾਰੀ ਯੋਜਨਾ';
      default:
        return 'Weekly Planner';
    }
  }

  String _getCreatePlanLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'योजना बनाएं';
      case 'mr':
        return 'योजना तयार करा';
      case 'ta':
        return 'திட்டம் உருவாக்கு';
      default:
        return 'Create Plan';
    }
  }

  String _getThisWeekTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'इस सप्ताह';
      case 'mr':
        return 'या आठवड्यात';
      case 'ta':
        return 'இந்த வாரம்';
      default:
        return 'This Week';
    }
  }

  String _getRecentPlansTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'हाल की योजनाएं';
      case 'mr':
        return 'अलीकडील योजना';
      case 'ta':
        return 'சமீபத்திய திட்டங்கள்';
      default:
        return 'Recent Plans';
    }
  }

  String _getStatusLabel(String status, String languageCode) {
    switch (status) {
      case 'completed':
        switch (languageCode) {
          case 'hi':
            return 'पूर्ण';
          case 'mr':
            return 'पूर्ण';
          case 'ta':
            return 'முடிந்தது';
          default:
            return 'Completed';
        }
      case 'in_progress':
        switch (languageCode) {
          case 'hi':
            return 'प्रगति में';
          case 'mr':
            return 'प्रगतीत';
          case 'ta':
            return 'முன்னேற்றத்தில்';
          default:
            return 'In Progress';
        }
      case 'draft':
        switch (languageCode) {
          case 'hi':
            return 'मसौदा';
          case 'mr':
            return 'मसुदा';
          case 'ta':
            return 'வரைவு';
          default:
            return 'Draft';
        }
      default:
        return status;
    }
  }

  String _getEditLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'संपादित करें';
      case 'mr':
        return 'संपादित करा';
      case 'ta':
        return 'திருத்து';
      default:
        return 'Edit';
    }
  }

  String _getDuplicateLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कॉपी करें';
      case 'mr':
        return 'कॉपी करा';
      case 'ta':
        return 'நகலெடு';
      default:
        return 'Duplicate';
    }
  }

  String _getDeleteLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'हटाएं';
      case 'mr':
        return 'हटवा';
      case 'ta':
        return 'நீக்கு';
      default:
        return 'Delete';
    }
  }

  String _getCreateNewPlanTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'नई पाठ योजना बनाएं';
      case 'mr':
        return 'नवीन धडा योजना तयार करा';
      case 'ta':
        return 'புதிய பாட திட்டம் உருவாக்கு';
      default:
        return 'Create New Lesson Plan';
    }
  }

  String _getCreateNewPlanDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'AI की मदद से व्यापक पाठ योजना बनाएं';
      case 'mr':
        return 'AI च्या मदतीने व्यापक धडा योजना तयार करा';
      case 'ta':
        return 'AI உதவியுடன் விரிவான பாட திட்டம் உருவாக்குங்கள்';
      default:
        return 'Create comprehensive lesson plans with AI assistance';
    }
  }

  String _getLessonDetailsTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'पाठ विवरण';
      case 'mr':
        return 'धड्याचे तपशील';
      case 'ta':
        return 'பாட விவரங்கள்';
      default:
        return 'Lesson Details';
    }
  }

  String _getLessonTitleLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'पाठ का शीर्षक';
      case 'mr':
        return 'धड्याचे शीर्षक';
      case 'ta':
        return 'பாடத்தின் தலைப்பு';
      default:
        return 'Lesson Title';
    }
  }

  String _getLessonTitleHint(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'उदा. सौर मंडल का परिचय';
      case 'mr':
        return 'उदा. सौर मंडळाचा परिचय';
      case 'ta':
        return 'உதா. சூரிய குடும்ப அறிமுகம்';
      default:
        return 'e.g. Introduction to Solar System';
    }
  }

  String _getSubjectLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'विषय';
      case 'mr':
        return 'विषय';
      case 'ta':
        return 'பாடம்';
      default:
        return 'Subject';
    }
  }

  String _getSubjectHint(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'विज्ञान, गणित, इतिहास';
      case 'mr':
        return 'विज्ञान, गणित, इतिहास';
      case 'ta':
        return 'அறிவியல், கணிதம், வரலாறு';
      default:
        return 'Science, Math, History';
    }
  }

  String _getGradeLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कक्षा';
      case 'mr':
        return 'वर्ग';
      case 'ta':
        return 'வகுப்பு';
      default:
        return 'Grade';
    }
  }

  String _getGradeHint(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कक्षा 4, 5वीं';
      case 'mr':
        return 'इयत्ता 4, 5वी';
      case 'ta':
        return '4, 5 ஆம் வகுப்பு';
      default:
        return 'Grade 4, 5th';
    }
  }

  String _getDurationLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'अवधि';
      case 'mr':
        return 'कालावधी';
      case 'ta':
        return 'காலம்';
      default:
        return 'Duration';
    }
  }

  String _getDurationHint(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return '45 मिनट';
      case 'mr':
        return '45 मिनिटे';
      case 'ta':
        return '45 நிமிடங்கள்';
      default:
        return '45 minutes';
    }
  }

  String _getDateLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'दिनांक';
      case 'mr':
        return 'दिनांक';
      case 'ta':
        return 'தேதி';
      default:
        return 'Date';
    }
  }

  String _getDateHint(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'दिनांक चुनें';
      case 'mr':
        return 'दिनांक निवडा';
      case 'ta':
        return 'தேதியைத் தேர்ந்தெடுக்கவும்';
      default:
        return 'Select date';
    }
  }

  String _getObjectivesLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'सीखने के उद्देश्य';
      case 'mr':
        return 'शिकण्याचे उद्दिष्ट';
      case 'ta':
        return 'கற்றல் நோக்கங்கள்';
      default:
        return 'Learning Objectives';
    }
  }

  String _getObjectivesHint(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'छात्र क्या सीखेंगे?';
      case 'mr':
        return 'विद्यार्थी काय शिकतील?';
      case 'ta':
        return 'மாணவர்கள் என்ன கற்பார்கள்?';
      default:
        return 'What will students learn?';
    }
  }

  String _getMaterialsLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'आवश्यक सामग्री';
      case 'mr':
        return 'आवश्यक साहित्य';
      case 'ta':
        return 'தேவையான பொருட்கள்';
      default:
        return 'Materials Needed';
    }
  }

  String _getMaterialsHint(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'चार्ट, मॉडल, वीडियो';
      case 'mr':
        return 'चार्ट, मॉडेल, व्हिडिओ';
      case 'ta':
        return 'அட்டவணை, மாதிரி, வீடியோ';
      default:
        return 'Charts, models, videos';
    }
  }

  String _getGeneratePlanLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'योजना बनाएं';
      case 'mr':
        return 'योजना तयार करा';
      case 'ta':
        return 'திட்டம் உருவாக்கு';
      default:
        return 'Generate Plan';
    }
  }

  String _getGeneratingPlanMessage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'पाठ योजना तैयार की जा रही है...';
      case 'mr':
        return 'धडा योजना तयार केली जात आहे...';
      case 'ta':
        return 'பாட திட்டம் தயாரிக்கப்படுகிறது...';
      default:
        return 'Generating lesson plan...';
    }
  }

  String _getTemplatesTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'पाठ योजना टेम्प्लेट';
      case 'mr':
        return 'धडा योजना टेम्प्लेट';
      case 'ta':
        return 'பாட திட்ட வார்ப்புருக்கள்';
      default:
        return 'Lesson Plan Templates';
    }
  }

  String _getTemplatesDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'तैयार टेम्प्लेट से शुरुआत करें';
      case 'mr':
        return 'तयार टेम्प्लेटपासून सुरुवात करा';
      case 'ta':
        return 'தயாரான வார்ப்புருக்களுடன் தொடங்குங்கள்';
      default:
        return 'Start with ready-made templates';
    }
  }

  String _getMathTemplatesTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'गणित टेम्प्लेट';
      case 'mr':
        return 'गणित टेम्प्लेट';
      case 'ta':
        return 'கணித வார்ப்புருக்கள்';
      default:
        return 'Math Templates';
    }
  }

  String _getMathTemplatesDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'गणित विषय के लिए योजनाएं';
      case 'mr':
        return 'गणित विषयासाठी योजना';
      case 'ta':
        return 'கணிதப் பாடத்திற்கான திட்டங்கள்';
      default:
        return 'Plans for mathematics subjects';
    }
  }

  String _getScienceTemplatesTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'विज्ञान टेम्प्लेट';
      case 'mr':
        return 'विज्ञान टेम्प्लेट';
      case 'ta':
        return 'அறிவியல் வார்ப்புருக்கள்';
      default:
        return 'Science Templates';
    }
  }

  String _getScienceTemplatesDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'विज्ञान विषय के लिए योजनाएं';
      case 'mr':
        return 'विज्ञान विषयासाठी योजना';
      case 'ta':
        return 'அறிவியல் பாடத்திற்கான திட்டங்கள்';
      default:
        return 'Plans for science subjects';
    }
  }

  String _getLanguageTemplatesTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'भाषा टेम्प्लेट';
      case 'mr':
        return 'भाषा टेम्प्लेट';
      case 'ta':
        return 'மொழி வார்ப்புருக்கள்';
      default:
        return 'Language Templates';
    }
  }

  String _getLanguageTemplatesDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'भाषा विषय के लिए योजनाएं';
      case 'mr':
        return 'भाषा विषयासाठी योजना';
      case 'ta':
        return 'மொழிப் பாடத்திற்கான திட்டங்கள்';
      default:
        return 'Plans for language subjects';
    }
  }

  String _getSocialTemplatesTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'सामाजिक विज्ञान टेम्प्लेट';
      case 'mr':
        return 'सामाजिक विज्ञान टेम्प्लेट';
      case 'ta':
        return 'சமூக அறிவியல் வார்ப்புருக்கள்';
      default:
        return 'Social Studies Templates';
    }
  }

  String _getSocialTemplatesDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'सामाजिक अध्ययन के लिए योजनाएं';
      case 'mr':
        return 'सामाजिक अभ्यासासाठी योजना';
      case 'ta':
        return 'சமூகப் படிப்புக்கான திட்டங்கள்';
      default:
        return 'Plans for social studies subjects';
    }
  }
}
