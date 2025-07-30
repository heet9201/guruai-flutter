import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/theme/responsive_layout.dart';
import '../bloc/app_bloc.dart';
import '../bloc/app_state.dart';

enum ContentType { textStory, worksheet, visualAid }

enum StoryContentType { story, explanation, example }

enum DrawingStyle { simpleLineArt, detailed, diagram }

enum VisualFormat { square, landscape, portrait, infographic }

class CreateContentScreen extends StatefulWidget {
  const CreateContentScreen({super.key});

  @override
  State<CreateContentScreen> createState() => _CreateContentScreenState();
}

class _CreateContentScreenState extends State<CreateContentScreen>
    with TickerProviderStateMixin {
  ContentType _selectedContentType = ContentType.textStory;
  bool _isGenerating = false;
  bool _showPreview = false;

  // Animation controllers
  late AnimationController _toggleAnimationController;
  late AnimationController _formAnimationController;
  late AnimationController _previewAnimationController;

  // Form controllers and state
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  // Text/Story form state
  String _selectedLanguage = 'en';
  Set<int> _selectedGrades = {3, 4, 5};
  StoryContentType _storyContentType = StoryContentType.story;

  // Worksheet form state
  File? _selectedImage;
  String _selectedSubject = 'math';
  double _difficultyLevel = 2.0;
  int _worksheetGrade = 4;

  // Visual Aid form state
  DrawingStyle _drawingStyle = DrawingStyle.simpleLineArt;
  VisualFormat _visualFormat = VisualFormat.square;

  // Generated content
  String _generatedContent = '';
  int _characterCount = 0;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _topicController.addListener(_updateWordCount);
    _descriptionController.addListener(_updateWordCount);
  }

  void _initializeAnimations() {
    _toggleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _previewAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _toggleAnimationController.forward();
    _formAnimationController.forward();
  }

  void _updateWordCount() {
    final text = _selectedContentType == ContentType.visualAid
        ? _descriptionController.text
        : _topicController.text;
    setState(() {
      _characterCount = text.length;
      _wordCount = text.trim().isEmpty ? 0 : text.trim().split(' ').length;
    });
  }

  @override
  void dispose() {
    _toggleAnimationController.dispose();
    _formAnimationController.dispose();
    _previewAnimationController.dispose();
    _topicController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onContentTypeChanged(ContentType type) {
    if (_selectedContentType != type) {
      setState(() {
        _selectedContentType = type;
        _showPreview = false;
      });
      _formAnimationController.reset();
      _formAnimationController.forward();
      _previewAnimationController.reset();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _generateContent() async {
    setState(() {
      _isGenerating = true;
    });

    // Simulate AI generation
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isGenerating = false;
      _showPreview = true;
      _generatedContent = _getSimulatedContent();
    });

    _previewAnimationController.forward();
  }

  String _getSimulatedContent() {
    switch (_selectedContentType) {
      case ContentType.textStory:
        return 'Once upon a time in a magical kingdom, there lived a young mathematician named Maya who discovered that numbers could dance and sing. Every morning, she would wake up to the sound of multiplication tables humming sweet melodies outside her window...';
      case ContentType.worksheet:
        return 'Worksheet: Basic Addition\n\n1. 15 + 23 = ___\n2. 34 + 17 = ___\n3. 28 + 35 = ___\n\nSolve the word problems:\n4. Maya has 12 apples. Her friend gives her 8 more. How many apples does Maya have now?';
      case ContentType.visualAid:
        return 'Visual aid generated: A colorful diagram showing the water cycle with labeled components including evaporation, condensation, precipitation, and collection.';
    }
  }

  void _saveToLibrary() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getSaveSuccessMessage(
            context.read<AppBloc>().state is AppLoaded
                ? (context.read<AppBloc>().state as AppLoaded).languageCode
                : 'en')),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        final languageCode = state is AppLoaded ? state.languageCode : 'en';

        return Scaffold(
          appBar: AppBar(
            title: Text(_getCreateContentTitle(languageCode)),
            elevation: 0,
            actions: [
              if (_showPreview)
                IconButton(
                  onPressed: _saveToLibrary,
                  icon: const Icon(Icons.save),
                  tooltip: _getSaveTooltip(languageCode),
                ),
            ],
          ),
          body: Column(
            children: [
              // Content Type Toggle Section
              Container(
                padding: EdgeInsets.all(
                    ResponsiveLayout.getHorizontalPadding(context)),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.3),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
                    ),
                  ),
                ),
                child: _buildContentTypeToggle(languageCode),
              ),

              // Main Content Area
              Expanded(
                child: Row(
                  children: [
                    // Form Section
                    Expanded(
                      flex: _showPreview ? 1 : 2,
                      child: AnimatedBuilder(
                        animation: _formAnimationController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              (1 - _formAnimationController.value) * -50,
                              0,
                            ),
                            child: Opacity(
                              opacity: _formAnimationController.value,
                              child: _buildFormSection(languageCode),
                            ),
                          );
                        },
                      ),
                    ),

                    // Preview Section
                    if (_showPreview)
                      Expanded(
                        flex: 1,
                        child: AnimatedBuilder(
                          animation: _previewAnimationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                (1 - _previewAnimationController.value) * 50,
                                0,
                              ),
                              child: Opacity(
                                opacity: _previewAnimationController.value,
                                child: _buildPreviewSection(languageCode),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomActionBar(languageCode),
        );
      },
    );
  }

  Widget _buildContentTypeToggle(String languageCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getSelectContentTypeTitle(languageCode),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _toggleAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _toggleAnimationController.value,
              child: Row(
                children: [
                  Expanded(
                    child: _buildToggleButton(
                      ContentType.textStory,
                      Icons.text_snippet,
                      _getTextStoryLabel(languageCode),
                      _getTextStoryDescription(languageCode),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildToggleButton(
                      ContentType.worksheet,
                      Icons.description,
                      _getWorksheetLabel(languageCode),
                      _getWorksheetDescription(languageCode),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildToggleButton(
                      ContentType.visualAid,
                      Icons.image,
                      _getVisualAidLabel(languageCode),
                      _getVisualAidDescription(languageCode),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildToggleButton(
      ContentType type, IconData icon, String label, String description) {
    final isSelected = _selectedContentType == type;

    return GestureDetector(
      onTap: () => _onContentTypeChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurface,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withOpacity(0.8)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection(String languageCode) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveLayout.getHorizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Dynamic form based on content type
          switch (_selectedContentType) {
            ContentType.textStory => _buildTextStoryForm(languageCode),
            ContentType.worksheet => _buildWorksheetForm(languageCode),
            ContentType.visualAid => _buildVisualAidForm(languageCode),
          },

          const SizedBox(height: 24),

          // Word/Character count
          _buildWordCountDisplay(languageCode),
        ],
      ),
    );
  }

  Widget _buildTextStoryForm(String languageCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTextStoryFormTitle(languageCode),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 20),

        // Language Dropdown
        _buildFormField(
          label: _getLanguageLabel(languageCode),
          child: DropdownButtonFormField<String>(
            value: _selectedLanguage,
            decoration: _getInputDecoration(_getLanguageHint(languageCode)),
            items: _getLanguageOptions(languageCode).map((lang) {
              return DropdownMenuItem(
                value: lang['code'],
                child: Text(lang['name'] ?? ''),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value ?? 'en';
              });
            },
          ),
        ),

        const SizedBox(height: 16),

        // Topic Input with Autocomplete
        _buildFormField(
          label: _getTopicLabel(languageCode),
          child: TextFormField(
            controller: _topicController,
            decoration: _getInputDecoration(_getTopicHint(languageCode)),
            maxLines: 2,
          ),
        ),

        const SizedBox(height: 16),

        // Content Type Selection
        _buildFormField(
          label: _getContentTypeLabel(languageCode),
          child: Wrap(
            spacing: 8,
            children: StoryContentType.values.map((type) {
              final isSelected = _storyContentType == type;
              return FilterChip(
                label: Text(_getStoryContentTypeLabel(type, languageCode)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _storyContentType = type;
                  });
                },
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Grade Level Multi-select
        _buildFormField(
          label: _getGradeLevelLabel(languageCode),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(8, (index) {
              final grade = index + 1;
              final isSelected = _selectedGrades.contains(grade);
              return FilterChip(
                label: Text('Grade $grade'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedGrades.add(grade);
                    } else {
                      _selectedGrades.remove(grade);
                    }
                  });
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildWorksheetForm(String languageCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getWorksheetFormTitle(languageCode),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 20),

        // Image Upload Area
        _buildFormField(
          label: _getImageUploadLabel(languageCode),
          child: GestureDetector(
            onTap: () => _showImageSourceDialog(),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  style: BorderStyle.solid,
                ),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getUploadImageText(languageCode),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getImageSourceText(languageCode),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Grade Level Selection
        _buildFormField(
          label: _getGradeLevelLabel(languageCode),
          child: DropdownButtonFormField<int>(
            value: _worksheetGrade,
            decoration: _getInputDecoration(_getGradeHint(languageCode)),
            items: List.generate(8, (index) {
              final grade = index + 1;
              return DropdownMenuItem(
                value: grade,
                child: Text('${_getGradeText(languageCode)} $grade'),
              );
            }),
            onChanged: (value) {
              setState(() {
                _worksheetGrade = value ?? 4;
              });
            },
          ),
        ),

        const SizedBox(height: 16),

        // Subject Category
        _buildFormField(
          label: _getSubjectLabel(languageCode),
          child: DropdownButtonFormField<String>(
            value: _selectedSubject,
            decoration: _getInputDecoration(_getSubjectHint(languageCode)),
            items: _getSubjectOptions(languageCode).map((subject) {
              return DropdownMenuItem(
                value: subject['code'],
                child: Text(subject['name'] ?? ''),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSubject = value ?? 'math';
              });
            },
          ),
        ),

        const SizedBox(height: 16),

        // Difficulty Level Slider
        _buildFormField(
          label: _getDifficultyLabel(languageCode),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Slider(
                value: _difficultyLevel,
                min: 1.0,
                max: 5.0,
                divisions: 4,
                label: _getDifficultyLevelText(
                    _difficultyLevel.round(), languageCode),
                onChanged: (value) {
                  setState(() {
                    _difficultyLevel = value;
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getEasyText(languageCode),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _getHardText(languageCode),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisualAidForm(String languageCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getVisualAidFormTitle(languageCode),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 20),

        // Description Text Area
        _buildFormField(
          label: _getDescriptionLabel(languageCode),
          child: TextFormField(
            controller: _descriptionController,
            decoration: _getInputDecoration(_getDescriptionHint(languageCode)),
            maxLines: 4,
            maxLength: 500,
          ),
        ),

        const SizedBox(height: 16),

        // Drawing Style Options
        _buildFormField(
          label: _getDrawingStyleLabel(languageCode),
          child: Wrap(
            spacing: 8,
            children: DrawingStyle.values.map((style) {
              final isSelected = _drawingStyle == style;
              return FilterChip(
                label: Text(_getDrawingStyleText(style, languageCode)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _drawingStyle = style;
                  });
                },
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Size/Format Selection
        _buildFormField(
          label: _getFormatLabel(languageCode),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3,
            children: VisualFormat.values.map((format) {
              final isSelected = _visualFormat == format;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _visualFormat = format;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getVisualFormatText(format, languageCode),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _getInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
    );
  }

  Widget _buildWordCountDisplay(String languageCode) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.text_fields,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getWordCountLabel(languageCode),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_getWordsText(languageCode)}: $_wordCount | ${_getCharactersText(languageCode)}: $_characterCount',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection(String languageCode) {
    return Container(
      padding: EdgeInsets.all(ResponsiveLayout.getHorizontalPadding(context)),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.preview,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _getPreviewTitle(languageCode),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Text(
                    _generatedContent,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generateContent,
              icon: const Icon(Icons.refresh),
              label: Text(_getRegenerateText(languageCode)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(String languageCode) {
    return Container(
      padding: EdgeInsets.all(ResponsiveLayout.getHorizontalPadding(context)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Progress indicator during generation
            if (_isGenerating)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getGeneratingText(languageCode),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _canGenerate() ? _generateContent : null,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(_getGenerateText(languageCode)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _canGenerate() {
    switch (_selectedContentType) {
      case ContentType.textStory:
        return _topicController.text.trim().isNotEmpty &&
            _selectedGrades.isNotEmpty;
      case ContentType.worksheet:
        return _selectedImage != null || _selectedSubject.isNotEmpty;
      case ContentType.visualAid:
        return _descriptionController.text.trim().isNotEmpty;
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(_getCameraText(context.read<AppBloc>().state
                        is AppLoaded
                    ? (context.read<AppBloc>().state as AppLoaded).languageCode
                    : 'en')),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(_getGalleryText(context.read<AppBloc>().state
                        is AppLoaded
                    ? (context.read<AppBloc>().state as AppLoaded).languageCode
                    : 'en')),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Localization methods
  String _getCreateContentTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'सामग्री बनाएं';
      case 'mr':
        return 'सामग्री तयार करा';
      case 'ta':
        return 'உள்ளடக்கம் உருவாக்கு';
      case 'te':
        return 'కంటెంట్ రూపొందించండి';
      default:
        return 'Create Content';
    }
  }

  String _getSelectContentTypeTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'सामग्री का प्रकार चुनें';
      case 'mr':
        return 'सामग्रीचा प्रकार निवडा';
      case 'ta':
        return 'உள்ளடக்க வகையைத் தேர்ந்தெடுக்கவும்';
      case 'te':
        return 'కంటెంట్ రకాన్ని ఎంచుకోండి';
      default:
        return 'Select Content Type';
    }
  }

  String _getTextStoryLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'पाठ/कहानी';
      case 'mr':
        return 'पाठ/कथा';
      case 'ta':
        return 'உரை/கதை';
      case 'te':
        return 'టెక్స్ట్/కథ';
      default:
        return 'Text/Story';
    }
  }

  String _getTextStoryDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'शैक्षिक कहानी और सामग्री';
      case 'mr':
        return 'शैक्षणिक कथा आणि सामग्री';
      case 'ta':
        return 'கல்விச் சார்ந்த கதை மற்றும் உள்ளடக்கம்';
      case 'te':
        return 'విద్యా కథలు మరియు కంటెంట్';
      default:
        return 'Educational stories and content';
    }
  }

  String _getWorksheetLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'वर्कशीट';
      case 'mr':
        return 'वर्कशीट';
      case 'ta':
        return 'பணித்தாள்';
      case 'te':
        return 'వర్క్‌షీట్';
      default:
        return 'Worksheet';
    }
  }

  String _getWorksheetDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'अभ्यास पत्र और प्रश्न';
      case 'mr':
        return 'सराव पत्रक आणि प्रश्न';
      case 'ta':
        return 'பயிற்சி தாள் மற்றும் கேள்விகள்';
      case 'te':
        return 'అభ్యాస పత్రాలు మరియు ప్రశ్నలు';
      default:
        return 'Practice sheets and questions';
    }
  }

  String _getVisualAidLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'दृश्य सहायता';
      case 'mr':
        return 'दृश्य साहाय्य';
      case 'ta':
        return 'காட்சி உதவி';
      case 'te':
        return 'దృశ్య సహాయం';
      default:
        return 'Visual Aid';
    }
  }

  String _getVisualAidDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'चित्र और आरेख';
      case 'mr':
        return 'चित्रे आणि आकृत्या';
      case 'ta':
        return 'படங்கள் மற்றும் வரைபடங்கள்';
      case 'te':
        return 'చిత్రాలు మరియు రేఖాచిత్రాలు';
      default:
        return 'Images and diagrams';
    }
  }

  String _getTextStoryFormTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कहानी विवरण';
      case 'mr':
        return 'कथा तपशील';
      case 'ta':
        return 'கதை விவரங்கள்';
      case 'te':
        return 'కథ వివరాలు';
      default:
        return 'Story Details';
    }
  }

  String _getWorksheetFormTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'वर्कशीट विवरण';
      case 'mr':
        return 'वर्कशीट तपशील';
      case 'ta':
        return 'பணித்தாள் விவரங்கள்';
      case 'te':
        return 'వర्क्शीట్ వివరాలు';
      default:
        return 'Worksheet Details';
    }
  }

  String _getVisualAidFormTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'दृश्य सहायता विवरण';
      case 'mr':
        return 'दृश्य साहाय्य तपशील';
      case 'ta':
        return 'காட்சி உதவி விவரங்கள்';
      case 'te':
        return 'దృశ్య సహాయం వివరాలు';
      default:
        return 'Visual Aid Details';
    }
  }

  String _getLanguageLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'भाषा';
      case 'mr':
        return 'भाषा';
      case 'ta':
        return 'மொழி';
      case 'te':
        return 'భాష';
      default:
        return 'Language';
    }
  }

  String _getTopicLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'विषय';
      case 'mr':
        return 'विषय';
      case 'ta':
        return 'தலைப்பு';
      case 'te':
        return 'విషయం';
      default:
        return 'Topic';
    }
  }

  String _getContentTypeLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'सामग्री प्रकार';
      case 'mr':
        return 'सामग्री प्रकार';
      case 'ta':
        return 'உள்ளடக்க வகை';
      case 'te':
        return 'కంటెంట్ రకం';
      default:
        return 'Content Type';
    }
  }

  String _getGradeLevelLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कक्षा स्तर';
      case 'mr':
        return 'वर्ग स्तर';
      case 'ta':
        return 'வகுப்பு நிலை';
      case 'te':
        return 'తరగతి స్థాయి';
      default:
        return 'Grade Level';
    }
  }

  List<Map<String, String>> _getLanguageOptions(String languageCode) {
    return [
      {'code': 'en', 'name': 'English'},
      {'code': 'hi', 'name': 'हिंदी'},
      {'code': 'mr', 'name': 'मराठी'},
      {'code': 'ta', 'name': 'தமிழ்'},
      {'code': 'te', 'name': 'తెలుగు'},
      {'code': 'kn', 'name': 'ಕನ್ನಡ'},
      {'code': 'ml', 'name': 'മലയാളം'},
      {'code': 'gu', 'name': 'ગુજરાતી'},
      {'code': 'bn', 'name': 'বাংলা'},
      {'code': 'pa', 'name': 'ਪੰਜਾਬੀ'},
    ];
  }

  List<Map<String, String>> _getSubjectOptions(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return [
          {'code': 'math', 'name': 'गणित'},
          {'code': 'science', 'name': 'विज्ञान'},
          {'code': 'english', 'name': 'अंग्रेजी'},
          {'code': 'hindi', 'name': 'हिंदी'},
          {'code': 'social', 'name': 'सामाजिक अध्ययन'},
        ];
      case 'mr':
        return [
          {'code': 'math', 'name': 'गणित'},
          {'code': 'science', 'name': 'विज्ञान'},
          {'code': 'english', 'name': 'इंग्रजी'},
          {'code': 'marathi', 'name': 'मराठी'},
          {'code': 'social', 'name': 'सामाजिक अभ्यास'},
        ];
      default:
        return [
          {'code': 'math', 'name': 'Mathematics'},
          {'code': 'science', 'name': 'Science'},
          {'code': 'english', 'name': 'English'},
          {'code': 'social', 'name': 'Social Studies'},
          {'code': 'art', 'name': 'Art & Craft'},
        ];
    }
  }

  String _getStoryContentTypeLabel(StoryContentType type, String languageCode) {
    switch (type) {
      case StoryContentType.story:
        switch (languageCode) {
          case 'hi':
            return 'कहानी';
          case 'mr':
            return 'कथा';
          case 'ta':
            return 'கதை';
          case 'te':
            return 'కథ';
          default:
            return 'Story';
        }
      case StoryContentType.explanation:
        switch (languageCode) {
          case 'hi':
            return 'व्याख्या';
          case 'mr':
            return 'स्पष्टीकरण';
          case 'ta':
            return 'விளக்கம்';
          case 'te':
            return 'వివరణ';
          default:
            return 'Explanation';
        }
      case StoryContentType.example:
        switch (languageCode) {
          case 'hi':
            return 'उदाहरण';
          case 'mr':
            return 'उदाहरण';
          case 'ta':
            return 'உதாரணம்';
          case 'te':
            return 'ఉదాహరణ';
          default:
            return 'Example';
        }
    }
  }

  String _getDrawingStyleText(DrawingStyle style, String languageCode) {
    switch (style) {
      case DrawingStyle.simpleLineArt:
        switch (languageCode) {
          case 'hi':
            return 'सरल रेखा कला';
          case 'mr':
            return 'साधी रेषा कला';
          case 'ta':
            return 'எளிய வரி கலை';
          case 'te':
            return 'సాధారణ లైన్ ఆర్ట్';
          default:
            return 'Simple Line Art';
        }
      case DrawingStyle.detailed:
        switch (languageCode) {
          case 'hi':
            return 'विस्तृत';
          case 'mr':
            return 'तपशीलवार';
          case 'ta':
            return 'விரிவான';
          case 'te':
            return 'వివరమైన';
          default:
            return 'Detailed';
        }
      case DrawingStyle.diagram:
        switch (languageCode) {
          case 'hi':
            return 'आरेख';
          case 'mr':
            return 'आकृती';
          case 'ta':
            return 'வரைபடம்';
          case 'te':
            return 'రేఖాచిత్రం';
          default:
            return 'Diagram';
        }
    }
  }

  String _getVisualFormatText(VisualFormat format, String languageCode) {
    switch (format) {
      case VisualFormat.square:
        switch (languageCode) {
          case 'hi':
            return 'वर्गाकार';
          case 'mr':
            return 'चौरस';
          case 'ta':
            return 'சதுரம்';
          case 'te':
            return 'చతురస్రం';
          default:
            return 'Square';
        }
      case VisualFormat.landscape:
        switch (languageCode) {
          case 'hi':
            return 'परिदृश्य';
          case 'mr':
            return 'आडवे';
          case 'ta':
            return 'நிலத்தோற்றம்';
          case 'te':
            return 'లాండ్‌స్కేప్';
          default:
            return 'Landscape';
        }
      case VisualFormat.portrait:
        switch (languageCode) {
          case 'hi':
            return 'चित्र';
          case 'mr':
            return 'उभे';
          case 'ta':
            return 'உருவப்படம்';
          case 'te':
            return 'పోర్ట్రెయిట్';
          default:
            return 'Portrait';
        }
      case VisualFormat.infographic:
        switch (languageCode) {
          case 'hi':
            return 'इन्फोग्राफिक';
          case 'mr':
            return 'माहितीचार्ट';
          case 'ta':
            return 'தகவல் விளக்கப்படம்';
          case 'te':
            return 'ఇన్ఫోగ్రాఫిక్';
          default:
            return 'Infographic';
        }
    }
  }

  String _getLanguageHint(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'भाषा चुनें';
      case 'mr':
        return 'भाषा निवडा';
      case 'ta':
        return 'மொழியைத் தேர்ந்தெடுக்கவும்';
      case 'te':
        return 'భాషను ఎంచుకోండి';
      default:
        return 'Select language';
    }
  }

  String _getTopicHint(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'विषय या थीम दर्ज करें';
      case 'mr':
        return 'विषय किंवा थीम प्रविष्ट करा';
      case 'ta':
        return 'தலைப்பு அல்லது கருப்பொருளை உள்ளிடவும்';
      case 'te':
        return 'విషయం లేదా థీమ్‌ను నమోదు చేయండి';
      default:
        return 'Enter topic or theme';
    }
  }

  String _getDescriptionHint(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'चित्र का विवरण दें';
      case 'mr':
        return 'चित्राचे वर्णन द्या';
      case 'ta':
        return 'படத்தின் விளக்கத்தை அளியுங்கள்';
      case 'te':
        return 'చిత్రం యొక్క వివరణను ఇవ్వండి';
      default:
        return 'Describe the image';
    }
  }

  String _getImageUploadLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'चित्र अपलोड करें';
      case 'mr':
        return 'चित्र अपलोड करा';
      case 'ta':
        return 'படத்தை பதிவேற்றவும்';
      case 'te':
        return 'చిత్రాన్ని అప్‌లోడ్ చేయండి';
      default:
        return 'Upload Image';
    }
  }

  String _getUploadImageText(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'चित्र अपलोड करें';
      case 'mr':
        return 'चित्र अपलोड करा';
      case 'ta':
        return 'படத்தை பதிவேற்றவும்';
      case 'te':
        return 'చిత్రాన్ని అప్‌లోడ్ చేయండి';
      default:
        return 'Upload Image';
    }
  }

  String _getImageSourceText(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कैमरा या गैलरी से';
      case 'mr':
        return 'कॅमेरा किंवा गॅलरीतून';
      case 'ta':
        return 'கேமரா அல்லது கேலரியிலிருந்து';
      case 'te':
        return 'కెమెరా లేదా గ్యాలరీ నుండి';
      default:
        return 'From camera or gallery';
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
      case 'te':
        return 'విషయం';
      default:
        return 'Subject';
    }
  }

  String _getDifficultyLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कठिनाई स्तर';
      case 'mr':
        return 'अडचण पातळी';
      case 'ta':
        return 'சிரमத்தின் நிலை';
      case 'te':
        return 'కష్టతా స్థాయి';
      default:
        return 'Difficulty Level';
    }
  }

  String _getDescriptionLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'विवरण';
      case 'mr':
        return 'वर्णन';
      case 'ta':
        return 'விளக்கம்';
      case 'te':
        return 'వివరణ';
      default:
        return 'Description';
    }
  }

  String _getDrawingStyleLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'ड्राइंग स्टाइल';
      case 'mr':
        return 'रेखाचित्र शैली';
      case 'ta':
        return 'வரைதல் பாணி';
      case 'te':
        return 'డ్రాయింగ్ స్టైల్';
      default:
        return 'Drawing Style';
    }
  }

  String _getFormatLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'आकार/प्रारूप';
      case 'mr':
        return 'आकार/स्वरूप';
      case 'ta':
        return 'அளவு/வடிவம்';
      case 'te':
        return 'పరిమాణం/ఫార్మాట్';
      default:
        return 'Size/Format';
    }
  }

  String _getWordCountLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'शब्द गणना';
      case 'mr':
        return 'शब्द मोजणी';
      case 'ta':
        return 'சொல் எண்ணிக்கை';
      case 'te':
        return 'పదాల లెక్క';
      default:
        return 'Word Count';
    }
  }

  String _getWordsText(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'शब्द';
      case 'mr':
        return 'शब्द';
      case 'ta':
        return 'சொற்கள்';
      case 'te':
        return 'పదాలు';
      default:
        return 'Words';
    }
  }

  String _getCharactersText(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'अक्षर';
      case 'mr':
        return 'अक्षरे';
      case 'ta':
        return 'எழுத்துகள்';
      case 'te':
        return 'అక్షరాలు';
      default:
        return 'Characters';
    }
  }

  String _getPreviewTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'पूर्वावलोकन';
      case 'mr':
        return 'पूर्वावलोकन';
      case 'ta':
        return 'முன்னோட்டம்';
      case 'te':
        return 'ప్రివ్యూ';
      default:
        return 'Preview';
    }
  }

  String _getGenerateText(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'जेनरेट करें';
      case 'mr':
        return 'निर्माण करा';
      case 'ta':
        return 'உருவாக்கு';
      case 'te':
        return 'రూపొందించు';
      default:
        return 'Generate';
    }
  }

  String _getRegenerateText(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'दोबारा जेनरेट करें';
      case 'mr':
        return 'पुन्हा निर्माण करा';
      case 'ta':
        return 'மீண்டும் உருவாக்கு';
      case 'te':
        return 'మళ్లీ రూపొందించు';
      default:
        return 'Regenerate';
    }
  }

  String _getGeneratingText(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'जेनरेट हो रहा है...';
      case 'mr':
        return 'निर्माण होत आहे...';
      case 'ta':
        return 'உருவாக்கப்படுகிறது...';
      case 'te':
        return 'రూపొందిస్తోంది...';
      default:
        return 'Generating...';
    }
  }

  String _getSaveTooltip(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'लाइब्रेरी में सेव करें';
      case 'mr':
        return 'लायब्ररीत सेव्ह करा';
      case 'ta':
        return 'நூலகத்தில் சேமிக்கவும்';
      case 'te':
        return 'లైబ్రరీలో సేవ్ చేయండి';
      default:
        return 'Save to Library';
    }
  }

  String _getSaveSuccessMessage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'लाइब्रेरी में सफलतापूर्वक सेव हो गया!';
      case 'mr':
        return 'लायब्ररीत यशस्वीपणे सेव्ह झाले!';
      case 'ta':
        return 'நூலகத்தில் வெற்றிகரமாக சேமிக்கப்பட்டது!';
      case 'te':
        return 'లైబ్రరీలో విజయవంతంగా సేవ్ చేయబడింది!';
      default:
        return 'Successfully saved to library!';
    }
  }

  String _getCameraText(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कैमरा';
      case 'mr':
        return 'कॅमेरा';
      case 'ta':
        return 'கேமரா';
      case 'te':
        return 'కెమెరా';
      default:
        return 'Camera';
    }
  }

  String _getGalleryText(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'गैलरी';
      case 'mr':
        return 'गॅलरी';
      case 'ta':
        return 'கேலரி';
      case 'te':
        return 'గ్యాలరీ';
      default:
        return 'Gallery';
    }
  }

  String _getGradeHint(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कक्षा चुनें';
      case 'mr':
        return 'वर्ग निवडा';
      case 'ta':
        return 'வகுப்பைத் தேர்ந்தெடுக்கவும்';
      case 'te':
        return 'తరగతిని ఎంచుకోండి';
      default:
        return 'Select grade';
    }
  }

  String _getSubjectHint(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'विषय चुनें';
      case 'mr':
        return 'विषय निवडा';
      case 'ta':
        return 'பாடத்தைத் தேர்ந்தெடுக்கவும்';
      case 'te':
        return 'విషయాన్ని ఎంచుకోండి';
      default:
        return 'Select subject';
    }
  }

  String _getGradeText(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कक्षा';
      case 'mr':
        return 'वर्ग';
      case 'ta':
        return 'வகுப்பு';
      case 'te':
        return 'తరగతి';
      default:
        return 'Grade';
    }
  }

  String _getDifficultyLevelText(int level, String languageCode) {
    final levels = {
      1: {
        'hi': 'बहुत आसान',
        'mr': 'अतिशय सोपे',
        'ta': 'மிக எளிதான',
        'te': 'చాలా సులభం',
        'en': 'Very Easy'
      },
      2: {
        'hi': 'आसान',
        'mr': 'सोपे',
        'ta': 'எளிதான',
        'te': 'సులభం',
        'en': 'Easy'
      },
      3: {
        'hi': 'मध्यम',
        'mr': 'मध्यम',
        'ta': 'நடுத்தர',
        'te': 'మధ్యమం',
        'en': 'Medium'
      },
      4: {
        'hi': 'कठिन',
        'mr': 'कठीण',
        'ta': 'கடினமான',
        'te': 'కష్టం',
        'en': 'Hard'
      },
      5: {
        'hi': 'बहुत कठिन',
        'mr': 'अतिशय कठीण',
        'ta': 'மிகவும் கடினமான',
        'te': 'చాలా కష్టం',
        'en': 'Very Hard'
      },
    };
    return levels[level]?[languageCode] ?? levels[level]?['en'] ?? 'Medium';
  }

  String _getEasyText(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'आसान';
      case 'mr':
        return 'सोपे';
      case 'ta':
        return 'எளிதான';
      case 'te':
        return 'సులభం';
      default:
        return 'Easy';
    }
  }

  String _getHardText(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कठिन';
      case 'mr':
        return 'कठीण';
      case 'ta':
        return 'கடினமான';
      case 'te':
        return 'కష্టం';
      default:
        return 'Hard';
    }
  }
}
