import 'dart:io';
import 'package:flutter/material.dart';
import 'package:clean_architect_cli/src/generators/template_generator.dart';
import 'package:clean_architect_cli/src/generators/folder_generator.dart';

void main() {
  runApp(const CleanArchitectGui());
}

class CleanArchitectGui extends StatelessWidget {
  const CleanArchitectGui({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clean Architect GUI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ProjectGeneratorPage(),
    );
  }
}

class ProjectGeneratorPage extends StatefulWidget {
  const ProjectGeneratorPage({super.key});

  @override
  State<ProjectGeneratorPage> createState() => _ProjectGeneratorPageState();
}

class _ProjectGeneratorPageState extends State<ProjectGeneratorPage> {
  final _nameController = TextEditingController();
  final _pathController = TextEditingController();
  String _projectType = 'mobile';
  String _stateManager = 'bloc';
  bool _isGenerating = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _pathController.text = Directory.current.path;
  }

  Future<void> _generateProject() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _statusMessage = 'Error: Project name cannot be empty');
      return;
    }

    setState(() {
      _isGenerating = true;
      _statusMessage = 'Generating \$name...';
    });

    try {
      final targetPath = '\${_pathController.text}/\$name';
      
      // Creating the project directory manually for the GUI
      final dir = Directory(targetPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      if (_projectType == 'mobile') {
        // Create base flutter project first
        await Process.run('flutter', ['create', targetPath]);
        
        // Generate Clean Architecture Scaffold
        final coreDirs = [
          '\$targetPath/lib/core/error',
          '\$targetPath/lib/core/network',
          '\$targetPath/lib/core/usecases',
          '\$targetPath/lib/core/utils',
          '\$targetPath/lib/core/theme',
          '\$targetPath/lib/features',
        ];
        FolderGenerator.createDirs(coreDirs);
        TemplateGenerator.createFile(
          '\$targetPath/lib/core/usecases/usecase.dart',
          TemplateGenerator.getUseCaseTemplate(),
        );
        TemplateGenerator.createFile(
          '\$targetPath/lib/injection_container.dart',
          TemplateGenerator.getInjectionContainerTemplate(),
        );
        TemplateGenerator.createFile(
          '\$targetPath/lib/core/theme/app_theme.dart',
          TemplateGenerator.getThemeTemplate(),
        );
        setState(() => _statusMessage = '✅ Mobile project \$name generated successfully at \$targetPath');
      } else {
        // Backend command logic requires a process run or refactoring. 
        // For simplicity in GUI, we run the process if it's backend.
        final result = await Process.run('dart', ['create', '-t', 'server-shelf', targetPath]);
        setState(() => _statusMessage = '✅ Backend project \$name generated successfully at \$targetPath\\n\${result.stdout}');
      }
    } catch (e) {
      setState(() => _statusMessage = 'Error: \$e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clean Architect Visual Builder'),
        elevation: 2,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create New Project',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Project Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.folder_special),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pathController,
                    decoration: const InputDecoration(
                      labelText: 'Target Directory',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.folder),
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _projectType,
                    decoration: const InputDecoration(
                      labelText: 'Project Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'mobile', child: Text('Flutter Mobile (Clean Architecture)')),
                      DropdownMenuItem(value: 'backend', child: Text('Dart Backend (Shelf/Frog)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _projectType = val);
                    },
                  ),
                  if (_projectType == 'mobile') ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _stateManager,
                      decoration: const InputDecoration(
                        labelText: 'State Management',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'bloc', child: Text('BLoC')),
                        DropdownMenuItem(value: 'riverpod', child: Text('Riverpod')),
                        DropdownMenuItem(value: 'provider', child: Text('Provider')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _stateManager = val);
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _isGenerating ? null : _generateProject,
                    icon: _isGenerating 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.rocket_launch),
                    label: Text(_isGenerating ? 'Generating...' : 'Generate Architecture'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _statusMessage!.startsWith('Error') ? Colors.redAccent : Colors.greenAccent,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
