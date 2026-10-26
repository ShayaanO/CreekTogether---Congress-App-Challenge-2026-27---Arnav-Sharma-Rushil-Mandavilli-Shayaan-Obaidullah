import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/speak_button.dart';

/// A single task item
class ChecklistItem {
  String title;
  bool isChecked;

  ChecklistItem({required this.title, this.isChecked = false});

  Map<String, dynamic> toJson() => {'title': title, 'isChecked': isChecked};

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
        title: (json['title'] ?? '') as String,
        isChecked: (json['isChecked'] ?? false) as bool,
      );
}

/// Who is using the app. Decides which pre-made lists are shown.
enum UserRole { student, parent, teacher }

extension UserRoleInfo on UserRole {
  String get label {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.parent:
        return 'Parent';
      case UserRole.teacher:
        return 'Teacher';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.student:
        return Icons.school;
      case UserRole.parent:
        return Icons.family_restroom;
      case UserRole.teacher:
        return Icons.menu_book;
    }
  }
}

/// Checklist screen: "My Tasks" (your own list) and "Pre-made Lists" (packs you can import).
class ChecklistTab extends StatefulWidget {
  const ChecklistTab({super.key});

  @override
  State<ChecklistTab> createState() => _ChecklistTabState();
}

class _ChecklistTabState extends State<ChecklistTab> {
  static const String _roleKey = 'checklist_user_role';
  static const String _tasksKey = 'checklist_my_tasks';

  // Who is using the app (null until they pick one)
  UserRole? _role;
  bool _loadingRole = true;

  // The user's own task list
  final List<ChecklistItem> _myCustomTasks = [];

  // Pre-made lists for each role. Users can import these into their own tasks.
  final Map<UserRole, Map<String, List<String>>> _templatesByRole = {
    UserRole.student: {
      '💼 Interview Prep & Job Requirements': [
        'Print 2 copies of your resume to bring with you',
        'Pick out a clean, neat outfit the night before',
        'Pack your ID card or driver license in your bag',
        'Look up the address and plan how you will travel there',
        'Set an alarm to arrive 15 minutes before the start time',
        'Prepare a clear 1-sentence description of your skills',
        'Practice answering: "Why do you want to work here?"',
      ],
      '🎓 College Requirements': [
        'Submit official high school transcripts',
        'Send standardized test scores (SAT/ACT if applicable)',
        'Submit completed application (Common App or institutional)',
        'Write and proofread personal statement essay',
        'Secure letters of recommendation from teachers or counselors',
        'Complete and submit FAFSA / financial aid forms',
        'Pay application fee or submit a fee waiver request',
      ],
      '🎒 Day of School Essentials': [
        'Laptop or tablet (fully charged) and power cords',
        'Notebooks, binders, and folders for active classes',
        'Pens, pencils, highlighters, and erasing tools',
        'Student ID card and wallet/transportation pass',
        'Refillable water bottle and snacks/lunch',
        'Headphones or earbuds for study sessions',
        'House keys and phone',
      ],
    },
    UserRole.parent: {
      '🌅 Morning Routine Support': [
        'Lay out clothes the night before',
        'Check that the backpack is packed and by the door',
        'Review the visual schedule for the day together',
        'Pack lunch, snacks, and any medication',
        'Confirm the ride or bus for the day',
        'Give a calm, predictable goodbye',
      ],
      '📅 School Meeting Prep (IEP / 504)': [
        'Bring a copy of the current IEP or 504 plan',
        'Write down your questions and concerns',
        'List what is working well at home',
        'Note goals you want to focus on this year',
        'Bring notes or reports from therapists or doctors',
        'Ask for any decisions to be sent to you in writing',
      ],
      '🚀 Planning for After School': [
        'Ask the school about the transition plan',
        'Talk with your student about their interests and strengths',
        'Gather important documents (ID, Social Security card, birth certificate)',
        'Contact your state vocational rehabilitation office',
        'Look into job training and college support programs',
        'Practice the travel route to work or classes together',
      ],
    },
    UserRole.teacher: {
      '🍎 Start of Day Classroom Setup': [
        'Review the daily schedule and post the visual schedule',
        'Check each student\'s accommodations (IEP / 504)',
        'Set out materials and sensory tools',
        'Charge tablets and communication devices',
        'Review notes from parents about health or behavior',
        'Check the room for safe, clear walkways',
      ],
      '📋 IEP Meeting Prep': [
        'Gather recent work samples and data',
        'Review progress toward each goal',
        'Note which accommodations are working',
        'Write down questions to ask the family',
        'Print copies of progress reports',
        'Prepare a list of the student\'s strengths to share',
      ],
      '🚌 Field Trip & Safety': [
        'Collect signed permission slips',
        'Review medical and allergy information',
        'Bring emergency contact numbers',
        'Confirm accessible transportation',
        'Arrange enough staff and chaperones',
        'Make a visual schedule of the trip for students',
      ],
    },
  };

  final TextEditingController _textController = TextEditingController();

  /// The pre-made lists for the current role (empty until a role is picked).
  Map<String, List<String>> get _templates {
    final role = _role;
    if (role == null) return {};
    return _templatesByRole[role] ?? {};
  }

  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadTasks();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // Loads the student's saved tasks (and which ones are checked off).
  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_tasksKey);
      if (raw == null) return;
      final list = jsonDecode(raw) as List<dynamic>;
      final loaded = list.map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>)).toList();
      if (!mounted) return;
      setState(() {
        _myCustomTasks
          ..clear()
          ..addAll(loaded);
      });
    } catch (_) {
      // If the saved list can't be read, start with an empty one.
    }
  }

  // Saves the task list to the phone. Called after every change.
  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tasksKey, jsonEncode(_myCustomTasks.map((t) => t.toJson()).toList()));
    } catch (_) {
      // Not saving is okay; the list still works until the app closes.
    }
  }

  // Loads the saved role. If there isn't one, this is the first time, so ask.
  Future<void> _loadRole() async {
    UserRole? role;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_roleKey);
      for (final r in UserRole.values) {
        if (r.name == saved) role = r;
      }
    } catch (_) {
      // If storage fails, we simply ask again.
    }

    if (!mounted) return;
    setState(() {
      _role = role;
      _loadingRole = false;
    });

    if (role == null) {
      await _askForRole(firstTime: true);
    }
  }

  // Shows the "who are you?" window.
  // First time: it can't be closed without picking.
  // Later (Change button): it has a Cancel button.
  Future<void> _askForRole({required bool firstTime}) async {
    final picked = await showDialog<UserRole>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Who is using this app?',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final role in UserRole.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 72,
                    child: FilledButton.icon(
                      icon: Icon(role.icon, size: 32),
                      label: Text(
                        role.label,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => Navigator.pop(dialogContext, role),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          if (!firstTime)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(fontSize: 18)),
            ),
        ],
      ),
    );

    if (!mounted) return;

    if (picked == null) {
      // First time and they closed it (for example, the Android back button): ask again.
      if (firstTime) await _askForRole(firstTime: true);
      return;
    }

    setState(() => _role = picked);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_roleKey, picked.name);
    } catch (_) {
      // Not saving is okay; they will just be asked again next time.
    }
  }

  // Adds whatever is typed in the box as a new task
  void _addTypedTask(BuildContext dialogContext) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() => _myCustomTasks.add(ChecklistItem(title: text)));
    _saveTasks();
    _textController.clear();
    Navigator.pop(dialogContext);
  }

  // Dialog box to create a new task
  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Task', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _textController,
          autofocus: true,
          style: const TextStyle(fontSize: 18),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _addTypedTask(dialogContext),
          decoration: const InputDecoration(
            hintText: 'Enter task name...',
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _textController.clear();
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
          FilledButton(
            onPressed: () => _addTypedTask(dialogContext),
            child: const Text('Add', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Copies a pre-made list into My Tasks (skipping any task already there)
  void _importTemplate(BuildContext tabContext, List<String> tasks) {
    final existing = _myCustomTasks.map((t) => t.title).toSet();
    final toAdd = tasks.where((t) => !existing.contains(t)).toList();

    setState(() {
      for (final title in toAdd) {
        _myCustomTasks.add(ChecklistItem(title: title));
      }
    });
    _saveTasks();

    // Jump to the My Tasks tab so they can see the new tasks
    DefaultTabController.of(tabContext).animateTo(0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          toAdd.isEmpty
              ? 'Those tasks are already in My Tasks'
              : 'Added ${toAdd.length} tasks to My Tasks',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Brief wait while we check whether a role was saved
    if (_loadingRole) {
      return const Center(child: CircularProgressIndicator());
    }

    final templates = _templates;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          toolbarHeight: 0,
          bottom: TabBar(
            labelColor: colors.primary,
            unselectedLabelColor: colors.onSurfaceVariant,
            indicatorColor: colors.primary,
            labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'My Tasks', icon: Icon(Icons.check_box_outlined, size: 28)),
              Tab(text: 'Pre-made Lists', icon: Icon(Icons.playlist_add_outlined, size: 28)),
            ],
          ),
        ),
        // The + button for adding your own task
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddTaskDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        body: Column(
          children: [
            // "Viewing as: Student" bar with a Change button
            if (_role != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(
                  children: [
                    Icon(_role!.icon, color: colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Viewing as: ${_role!.label}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Change', style: TextStyle(fontSize: 16)),
                      onPressed: () => _askForRole(firstTime: false),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  // --- TAB 1: MY TASKS ---
                  _myCustomTasks.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              'No tasks yet!\n\nGo to "Pre-made Lists" to import a pack or tap the + button below to add your own.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, color: colors.onSurfaceVariant, height: 1.4),
                            ),
                          ),
                        )
                      : ListView.builder(
                          // Extra space at the bottom so the + button doesn't cover the last task
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
                          itemCount: _myCustomTasks.length,
                          itemBuilder: (context, index) {
                            final item = _myCustomTasks[index];
                            return Card(
                              child: CheckboxListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                title: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    decoration: item.isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                                    color: item.isChecked ? colors.onSurfaceVariant : colors.onSurface,
                                  ),
                                ),
                                value: item.isChecked,
                                controlAffinity: ListTileControlAffinity.leading,
                                // Speaker (when Read aloud is on) + delete button
                                secondary: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SpeakButton(item.title),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: 'Delete task',
                                      onPressed: () {
                                        setState(() => _myCustomTasks.removeAt(index));
                                        _saveTasks();
                                      },
                                    ),
                                  ],
                                ),
                                onChanged: (val) {
                                  setState(() => item.isChecked = val ?? false);
                                  _saveTasks();
                                },
                              ),
                            );
                          },
                        ),

                  // --- TAB 2: PRE-MADE LISTS (for the chosen role) ---
                  ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                    itemCount: templates.length,
                    itemBuilder: (tabContext, index) {
                      final entry = templates.entries.elementAt(index);
                      final String categoryTitle = entry.key;
                      final List<String> taskList = entry.value;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        clipBehavior: Clip.antiAlias,
                        child: ExpansionTile(
                          iconColor: colors.primary,
                          collapsedIconColor: colors.onSurfaceVariant,
                          tilePadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          leading: Icon(Icons.folder_special_outlined, color: colors.primary, size: 32),
                          title: Text(
                            categoryTitle,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.onSurface),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '${taskList.length} action steps',
                              style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
                            ),
                          ),
                          children: [
                            const Divider(height: 1),

                            // Preview of the tasks inside this list
                            for (final task in taskList)
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
                                leading: Icon(Icons.circle_outlined, size: 16, color: colors.onSurfaceVariant),
                                trailing: SpeakButton(task),
                                title: Text(
                                  task,
                                  style: TextStyle(fontSize: 16, color: colors.onSurfaceVariant, height: 1.3),
                                ),
                              ),

                            const Divider(height: 1),

                            // Button to copy this list into My Tasks
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24),
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: FilledButton.icon(
                                  icon: const Icon(Icons.add_to_photos, size: 24),
                                  label: const Text(
                                    'Import into My Tasks',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () => _importTemplate(tabContext, taskList),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}