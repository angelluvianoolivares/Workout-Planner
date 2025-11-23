// ignore_for_file: constant_identifier_names, non_constant_identifier_names
import 'dart:math';

const List<String> EQUIPMENT = [
  'barbell',
  'dumbbell',
  'machine',
  'cable',
  'kettlebell',
  'bench',
  'rack',
  'smith',
  'bodyweight',
  'bar',
  'bands',
  'trx',
];

//INJURY TYPES AND THEIR AFFECTED EXERCISES
const Map<String, Map<String, dynamic>> INJURY_RESTRICTIONS = {
  'shoulder': {
    'avoid_exercises': ['bench', 'ohp', 'dbohp', 'incline', 'dips', 'upright'],
    'alternative_exercises': ['pushup', 'legpress', 'goblet', 'legext'],
    'severity_high': ['bench', 'ohp', 'dips'],
    'severity_medium': ['latraise', 'fly'],
    'severity_low': []
  },
  'lower_back': {
    'avoid_exercises': ['squat', 'dl', 'rdl', 'goodmorning', 'row'],
    'alternative_exercises': ['legpress', 'legext', 'legcurl', 'machinerow'],
    'severity_high': ['dl', 'squat', 'rdl'],
    'severity_medium': ['row', 'goodmorning'],
    'severity_low': ['hipthrust']
  },
  'knee': {
    'avoid_exercises': ['squat', 'fsquat', 'lunges', 'legext', 'boxjump'],
    'alternative_exercises': ['legcurl', 'hipthrust', 'glutebridge', 'deadlift'],
    'severity_high': ['squat', 'fsquat', 'legext'],
    'severity_medium': ['lunges', 'legpress'],
    'severity_low': ['stepup']
  },
  'elbow': {
    'avoid_exercises': ['curl', 'tric', 'skull', 'closepress', 'dips'],
    'alternative_exercises': ['latraise', 'fly', 'calf', 'legwork'],
    'severity_high': ['curl', 'skull', 'closepress'],
    'severity_medium': ['tric', 'dips'],
    'severity_low': []
  },
  'wrist': {
    'avoid_exercises': ['bench', 'ohp', 'curl', 'row', 'pushup'],
    'alternative_exercises': ['legpress', 'legext', 'legcurl', 'calf'],
    'severity_high': ['bench', 'ohp', 'pushup'],
    'severity_medium': ['curl', 'row'],
    'severity_low': ['latraise']
  },
  'hip': {
    'avoid_exercises': ['squat', 'dl', 'lunges', 'hipthrust', 'goodmorning'],
    'alternative_exercises': ['legext', 'legcurl', 'upperonly'],
    'severity_high': ['squat', 'dl', 'lunges'],
    'severity_medium': ['hipthrust', 'goodmorning'],
    'severity_low': ['legpress']
  },
};

const Map<String, int> EXERCISE_DIFFICULTY = {
  // Beginner (1-3)
  'goblet': 1,
  'pushup': 1,
  'plank': 1,
  'machinerow': 1,
  'legpress': 2,
  'dbbench': 2,
  'dbohp': 2,
  'latpulldown': 2,
  
  // Intermediate (4-6)
  'bench': 4,
  'squat': 4,
  'row': 4,
  'ohp': 4,
  'rdl': 5,
  'dbrow': 4,
  'incline': 5,
  
  // Advanced (7-10)
  'fsquat': 7,
  'dl': 8,
  'pullup': 7,
  'dips': 6,
  'snatch': 9,
  'clean': 8,
};

const Map<String, List<String>> EXERCISE_MUSCLE_GROUPS = {
  'squat': ['quads', 'glutes', 'core'],
  'fsquat': ['quads', 'core'],
  'goblet': ['quads', 'glutes'],
  'legpress': ['quads', 'glutes'],
  'rdl': ['hamstrings', 'glutes', 'lower_back'],
  'dl': ['hamstrings', 'glutes', 'lower_back', 'traps'],
  'hipthrust': ['glutes', 'hamstrings'],
  'bench': ['chest', 'triceps', 'front_delts'],
  'dbbench': ['chest', 'triceps', 'front_delts'],
  'pushup': ['chest', 'triceps', 'core'],
  'ohp': ['front_delts', 'triceps', 'core'],
  'dbohp': ['front_delts', 'triceps'],
  'row': ['lats', 'rhomboids', 'rear_delts', 'biceps'],
  'dbrow': ['lats', 'rhomboids', 'rear_delts', 'biceps'],
  'latpulldown': ['lats', 'biceps'],
  'pullup': ['lats', 'biceps', 'core'],
  'curl': ['biceps'],
  'tric': ['triceps'],
  'skull': ['triceps'],
  'latraise': ['side_delts'],
  'fly': ['chest'],
  'legcurl': ['hamstrings'],
  'legext': ['quads'],
  'calf': ['calves'],
  'coreplank': ['core'],
  'corecable': ['core'],
  'hanging': ['core', 'hip_flexors'],
};

const Map<String, Map<String, int>> MUSCLE_GROUP_VOLUME = {
  'beginner': {
    'chest': 12,
    'back': 12,
    'quads': 12,
    'hamstrings': 8,
    'glutes': 10,
    'front_delts': 6,
    'side_delts': 6,
    'rear_delts': 6,
    'biceps': 6,
    'triceps': 6,
    'core': 6,
  },
  'intermediate': {
    'chest': 16,
    'back': 16,
    'quads': 16,
    'hamstrings': 12,
    'glutes': 14,
    'front_delts': 8,
    'side_delts': 8,
    'rear_delts': 8,
    'biceps': 8,
    'triceps': 8,
    'core': 8,
  },
  'advanced': {
    'chest': 20,
    'back': 20,
    'quads': 20,
    'hamstrings': 16,
    'glutes': 18,
    'front_delts': 12,
    'side_delts': 12,
    'rear_delts': 10,
    'biceps': 10,
    'triceps': 10,
    'core': 10,
  },
};

const Map<String, Map<String, dynamic>> LEVEL_PARAMS = {
  'beginner': {
    'setsMain': 3,
    'setsAcc': 2,
    'repMain': [8, 10],
    'repAcc': [10, 15],
    'restMain': 120,
    'restAcc': 60,
    'maxDifficulty': 4,
  },
  'intermediate': {
    'setsMain': 4,
    'setsAcc': 3,
    'repMain': [6, 8],
    'repAcc': [8, 12],
    'restMain': 150,
    'restAcc': 75,
    'maxDifficulty': 7,
  },
  'advanced': {
    'setsMain': 5,
    'setsAcc': 3,
    'repMain': [4, 6],
    'repAcc': [6, 10],
    'restMain': 180,
    'restAcc': 90,
    'maxDifficulty': 10,
  },
};

const Map<String, Map<String, dynamic>> GOAL_TWEAKS = {
  'strength': {'repMainDelta': -2, 'repAccDelta': -2, 'restBoost': 1.2, 'focusCompound': true},
  'hypertrophy': {'repMainDelta': 2, 'repAccDelta': 2, 'restBoost': 0.9, 'focusCompound': false},
  'endurance': {'repMainDelta': 4, 'repAccDelta': 4, 'restBoost': 0.8, 'focusCompound': false},
  'recomp': {'repMainDelta': 0, 'repAccDelta': 0, 'restBoost': 1.0, 'focusCompound': true},
  'athletic': {'repMainDelta': 0, 'repAccDelta': -2, 'restBoost': 1.1, 'focusCompound': true},
};

const Map<int, List<List<String>>> SPLITS = {
  2: [['full'], ['full']],
  3: [['push'], ['pull'], ['legs']],
  4: [['upper'], ['lower'], ['upper'], ['lower']],
  5: [['upper'], ['lower'], ['push'], ['pull'], ['full']],
  6: [['push'], ['pull'], ['legs'], ['upper'], ['lower'], ['full']],
};

const Map<String, Map<String, List<String>>> BLUEPRINT = {
  'full': {
    'main': ['squat/goblet/legpress', 'bench/dbbench/pushup', 'row/dbrow/latpulldown/pullup'],
    'acc': ['rdl/hipthrust', 'latraise/fly', 'curl/tric', 'coreplank/corecable/hanging']
  },
  'upper': {
    'main': ['bench/dbbench/pushup', 'row/latpulldown/pullup', 'ohp/dbohp'],
    'acc': ['latraise/fly', 'curl', 'tric', 'coreplank/corecable/hanging']
  },
  'lower': {
    'main': ['squat/goblet/legpress', 'rdl/dl/hipthrust'],
    'acc': ['legext', 'legcurl', 'calf', 'coreplank']
  },
  'push': {
    'main': ['bench/dbbench/pushup', 'ohp/dbohp'],
    'acc': ['fly', 'tric', 'latraise', 'coreplank']
  },
  'pull': {
    'main': ['row/dbrow/latpulldown/pullup', 'rdl/dl'],
    'acc': ['curl', 'legcurl', 'coreplank/corecable/hanging']
  },
  'legs': {
    'main': ['squat/goblet/legpress', 'rdl/hipthrust/dl'],
    'acc': ['legext', 'legcurl', 'calf', 'coreplank']
  }
};

class Exercise {
  final String id;
  final String name;
  final String muscle;
  final String type;
  final List<String> equip;
  final int difficulty;
  final List<String> muscleGroups;
  final String? substitutionFor;

  Exercise({
    required this.id,
    required this.name,
    required this.muscle,
    required this.type,
    required this.equip,
    this.difficulty = 5,
    this.muscleGroups = const [],
    this.substitutionFor,
  });
}

final List<Exercise> EXERCISES = [
  //LEGS
  Exercise(id: 'squat', name: 'Back Squat', muscle: 'legs', type: 'compound', equip: ['barbell', 'rack'], difficulty: 6, muscleGroups: ['quads', 'glutes', 'core']),
  Exercise(id: 'fsquat', name: 'Front Squat', muscle: 'legs', type: 'compound', equip: ['barbell', 'rack'], difficulty: 7, muscleGroups: ['quads', 'core']),
  Exercise(id: 'goblet', name: 'Goblet Squat', muscle: 'legs', type: 'compound', equip: ['dumbbell', 'kettlebell'], difficulty: 3, muscleGroups: ['quads', 'glutes'], substitutionFor: 'knee'),
  Exercise(id: 'legpress', name: 'Leg Press', muscle: 'legs', type: 'compound', equip: ['machine'], difficulty: 4, muscleGroups: ['quads', 'glutes'], substitutionFor: 'lower_back'),
  Exercise(id: 'rdl', name: 'Romanian Deadlift', muscle: 'posterior', type: 'compound', equip: ['barbell', 'dumbbell'], difficulty: 5, muscleGroups: ['hamstrings', 'glutes', 'lower_back']),
  Exercise(id: 'dl', name: 'Deadlift', muscle: 'posterior', type: 'compound', equip: ['barbell'], difficulty: 8, muscleGroups: ['hamstrings', 'glutes', 'lower_back', 'traps']),
  Exercise(id: 'hipthrust', name: 'Hip Thrust', muscle: 'glutes', type: 'compound', equip: ['barbell', 'bench'], difficulty: 4, muscleGroups: ['glutes', 'hamstrings'], substitutionFor: 'lower_back'),
  
  //CHEST
  Exercise(id: 'bench', name: 'Barbell Bench Press', muscle: 'chest', type: 'compound', equip: ['barbell', 'bench'], difficulty: 5, muscleGroups: ['chest', 'triceps', 'front_delts']),
  Exercise(id: 'dbbench', name: 'DB Bench Press', muscle: 'chest', type: 'compound', equip: ['dumbbell', 'bench'], difficulty: 4, muscleGroups: ['chest', 'triceps', 'front_delts']),
  Exercise(id: 'pushup', name: 'Push-up', muscle: 'chest', type: 'compound', equip: ['bodyweight'], difficulty: 2, muscleGroups: ['chest', 'triceps', 'core'], substitutionFor: 'shoulder'),
  
  //SHOULDERS
  Exercise(id: 'ohp', name: 'Overhead Press', muscle: 'shoulders', type: 'compound', equip: ['barbell'], difficulty: 6, muscleGroups: ['front_delts', 'triceps', 'core']),
  Exercise(id: 'dbohp', name: 'DB Shoulder Press', muscle: 'shoulders', type: 'compound', equip: ['dumbbell'], difficulty: 4, muscleGroups: ['front_delts', 'triceps']),
  
  //BACK
  Exercise(id: 'row', name: 'Barbell Row', muscle: 'back', type: 'compound', equip: ['barbell'], difficulty: 6, muscleGroups: ['lats', 'rhomboids', 'rear_delts', 'biceps']),
  Exercise(id: 'dbrow', name: 'DB Row', muscle: 'back', type: 'compound', equip: ['dumbbell', 'bench'], difficulty: 4, muscleGroups: ['lats', 'rhomboids', 'rear_delts', 'biceps'], substitutionFor: 'lower_back'),
  Exercise(id: 'latpulldown', name: 'Lat Pulldown', muscle: 'back', type: 'compound', equip: ['machine', 'cable'], difficulty: 3, muscleGroups: ['lats', 'biceps']),
  Exercise(id: 'pulldown', name: 'Assisted Pull-up / Pull-down', muscle: 'back', type: 'compound', equip: ['machine'], difficulty: 4, muscleGroups: ['lats', 'biceps']),
  Exercise(id: 'pullup', name: 'Pull-up', muscle: 'back', type: 'compound', equip: ['bodyweight', 'bar'], difficulty: 7, muscleGroups: ['lats', 'core', 'biceps']),
  
  //ACCESSORIES
  Exercise(id: 'curl', name: 'Bicep Curl', muscle: 'biceps', type: 'accessory', equip: ['dumbbell', 'barbell', 'cable'], difficulty: 2, muscleGroups: ['biceps']),
  Exercise(id: 'tric', name: 'Triceps Pushdown', muscle: 'triceps', type: 'accessory', equip: ['cable'], difficulty: 2, muscleGroups: ['triceps']),
  Exercise(id: 'skull', name: 'Skullcrusher', muscle: 'triceps', type: 'accessory', equip: ['barbell', 'dumbbell', 'bench'], difficulty: 4, muscleGroups: ['triceps']),
  Exercise(id: 'latraise', name: 'Lateral Raise', muscle: 'shoulders', type: 'accessory', equip: ['dumbbell', 'cable'], difficulty: 2, muscleGroups: ['side_delts']),
  Exercise(id: 'fly', name: 'Chest Fly', muscle: 'chest', type: 'accessory', equip: ['dumbbell', 'cable', 'machine'], difficulty: 3, muscleGroups: ['chest']),
  Exercise(id: 'legcurl', name: 'Leg Curl', muscle: 'posterior', type: 'accessory', equip: ['machine'], difficulty: 2, muscleGroups: ['hamstrings']),
  Exercise(id: 'legext', name: 'Leg Extension', muscle: 'quads', type: 'accessory', equip: ['machine'], difficulty: 2, muscleGroups: ['quads']),
  Exercise(id: 'calf', name: 'Calf Raise', muscle: 'calves', type: 'accessory', equip: ['machine', 'smith', 'bodyweight'], difficulty: 1, muscleGroups: ['calves']),
  
  //CORE
  Exercise(id: 'coreplank', name: 'Plank', muscle: 'core', type: 'core', equip: ['bodyweight'], difficulty: 1, muscleGroups: ['core']),
  Exercise(id: 'corecable', name: 'Cable Crunch', muscle: 'core', type: 'core', equip: ['cable'], difficulty: 2, muscleGroups: ['core']),
  Exercise(id: 'hanging', name: 'Hanging Knee Raise', muscle: 'core', type: 'core', equip: ['bar'], difficulty: 4, muscleGroups: ['core', 'hip_flexors']),
];

class InjuryInfo {
  final String type;
  final String severity;
  final bool isRecovering;

  InjuryInfo({
    required this.type,
    required this.severity,
    this.isRecovering = false,
  });
}

class WorkoutExercise {
  final String id;
  final String name;
  final int sets;
  final List<int> reps;
  final int rest;
  final String? notes;

  WorkoutExercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.rest,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sets': sets,
      'reps': reps,
      'rest': rest,
      if (notes != null) 'notes': notes,
    };
  }
}

class WorkoutDay {
  final String name;
  final String focus;
  final List<WorkoutExercise> main;
  final List<WorkoutExercise> accessories;
  final String note;

  WorkoutDay({
    required this.name,
    required this.focus,
    required this.main,
    required this.accessories,
    required this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'focus': focus,
      'main': main.map((e) => e.toJson()).toList(),
      'accessories': accessories.map((e) => e.toJson()).toList(),
      'note': note,
    };
  }
}

class WorkoutPlan {
  final Map<String, dynamic> meta;
  final List<WorkoutDay> plan;
  final Map<String, int>? muscleGroupVolume;

  WorkoutPlan({
    required this.meta, 
    required this.plan,
    this.muscleGroupVolume,
  });
}

//HELPER FUNCTIONS
bool isExerciseSafe(Exercise exercise, List<InjuryInfo> injuries, String level) {
  final maxDiff = LEVEL_PARAMS[level]?['maxDifficulty'] ?? 10;
  if (exercise.difficulty > maxDiff) return false;

  //CHECK INJURIES
  for (final injury in injuries) {
    final restriction = INJURY_RESTRICTIONS[injury.type];
    if (restriction == null) continue;

    List<String> avoidList = [];
    switch (injury.severity) {
      case 'high':
        avoidList = List<String>.from(restriction['severity_high'] ?? []);
        avoidList.addAll(List<String>.from(restriction['severity_medium'] ?? []));
        break;
      case 'medium':
        avoidList = List<String>.from(restriction['severity_medium'] ?? []);
        break;
      case 'low':
        if (!injury.isRecovering) {
          avoidList = List<String>.from(restriction['severity_low'] ?? []);
        }
        break;
    }
    if (avoidList.contains(exercise.id)) return false;
  }
  return true;
}

Exercise? resolveSlot(String slot, Set<String> availableEquip, List<InjuryInfo> injuries, String level, Map<String, int> currentVolume) {
  final options = slot.split('/').map((id) => EXERCISES.where((e) => e.id == id).firstOrNull).where((e) => e != null).cast<Exercise>().toList();

  var validOptions = options.where((e) {
    final hasEquip = e.equip.any((eq) => availableEquip.contains(eq));
    final isSafe = isExerciseSafe(e, injuries, level);

    return hasEquip && isSafe;
  }).toList();

  if (validOptions.isEmpty && injuries.isNotEmpty) {
    validOptions = EXERCISES.where((e) {
      final hasEquip = e.equip.any((eq) => availableEquip.contains(eq));
      final isSafe = isExerciseSafe(e, injuries, level);
      final isSimilar = e.muscleGroups.any((mg) => options.any((opt) => opt.muscleGroups.contains(mg)));

      return hasEquip && isSafe && isSimilar;
    }).toList();
  }

  if (validOptions.isEmpty) {
    validOptions = options;
  }

  if (validOptions.length > 1) {
    validOptions.sort((a, b) {
      int aScore = 0;
      int bScore = 0;

      for (final mg in a.muscleGroups) {
        aScore += (currentVolume[mg] ?? 0);
      }
      for (final mg in b.muscleGroups) {
        bScore += (currentVolume[mg] ?? 0);
      }

      return aScore.compareTo(bScore);
    });
  }

  return validOptions.isNotEmpty ? validOptions[Random().nextInt(min(validOptions.length, 3))] : null;
}

List<int> repRange(List<int> base, int delta) {
  return [max(3, base[0] + delta), max(4, base[1] + delta)];
}

Map<String, dynamic> progressionAdjust(Map<String, dynamic> levelParams, String adherence, int rpe, int weekNumber) {
  final p = Map<String, dynamic>.from(levelParams);

  if (weekNumber % 4 == 0) {
    p['setsMain'] = max(2, (p['setsMain'] as int) - 1);
    p['setsAcc'] = max(1, (p['setsAcc'] as int) - 1);
    return p;
  }

  if (adherence == 'yes' && rpe <= 7) {
    p['setsMain'] = (p['setsMain'] as int) + 1;
  }
  if (adherence == 'no' || rpe >= 9) {
    p['setsMain'] = max(2, (p['setsMain'] as int) - 1);
    p['setsAcc'] = max(1, (p['setsAcc'] as int) - 1);
  }
  
  return p;
}

String fmtRange(List<int> range) {
  return '${range[0]} - ${range[1]}';
}

// Main generation function
WorkoutPlan generatePlan({
  String level = 'beginner',
  int days = 3,
  String goal = 'recomp',
  List<String> equipment = const [],
  List<InjuryInfo> injuries = const [],
  String adherence = 'yes',
  int rpe = 7,
  int week = 1,
  bool prioritizeCompounds = true,
  int? targetVolume,
}) {
  days = min(6, max(2, days));
  final split = SPLITS[days] ?? SPLITS[3]!;
  final base = LEVEL_PARAMS[level] ?? LEVEL_PARAMS['beginner']!;
  final g = GOAL_TWEAKS[goal] ?? GOAL_TWEAKS['recomp']!;

  final repMain = repRange(List<int>.from(base['repMain']), g['repMainDelta']);
  final repAcc = repRange(List<int>.from(base['repAcc']), g['repAccDelta']);

  final tweaked = {
    ...base,
    'restMain': (base['restMain']! * g['restBoost']!).round(),
    'restAcc': (base['restAcc']! * g['restBoost']!).round(),
  };

  final prog = progressionAdjust(tweaked, adherence, rpe, week);
  final avail = equipment.toSet();

  final muscleGroupVolume = <String, int> {};
  //final targetMuscleVolume = MUSCLE_GROUP_VOLUME[level] ?? MUSCLE_GROUP_VOLUME['intermediate']!;

  final daysOut = <WorkoutDay>[];
  final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  for (var i = 0; i < split.length; i++) {
    final focus = split[i][0];
    final bp = BLUEPRINT[focus]!;

    final mains = <Exercise> [];
    for (final slot in bp['main']!) {
      final ex = resolveSlot(slot, avail, injuries, level, muscleGroupVolume);
      if (ex != null) {
        mains.add(ex);
        for (final mg in ex.muscleGroups) {
          muscleGroupVolume[mg] = (muscleGroupVolume[mg] ?? 0) + (prog['setsMain'] as int);
        }
      }
    }

    final accSlots = List<String>.from(bp['acc']!);
    accSlots.shuffle();
    
    final accs = <Exercise> [];
    for (final slot in accSlots.take(3)) {
      final ex = resolveSlot(slot, avail, injuries, level, muscleGroupVolume);
      if (ex != null) {
        accs.add(ex);
        for (final mg in ex.muscleGroups) {
          muscleGroupVolume[mg] = (muscleGroupVolume[mg] ?? 0) + (prog['setsAcc'] as int);
        }
      }
    }

    final dayName = '${dayNames[i % 6]} — ${focus.toUpperCase()}';

    String note = week % 4 == 0 ? 'Deload Week: Leave 3-4 RIR and Reduce Weight ~10-15%.' : 'Leave 1-2 RIR. Increase Next Week if Top Sets ≤7 RPE.';

    if (injuries.isNotEmpty) {
      final injuryTypes = injuries.map((i) => i.type).join(', ');
      note += ' Modified for $injuryTypes.';
    }

    daysOut.add(WorkoutDay(
      name: dayName,
      focus: focus,
      main: mains
          .map((x) => WorkoutExercise(
                id: x.id,
                name: x.name,
                sets: prog['setsMain'],
                reps: repMain,
                rest: prog['restMain'],
                notes: x.difficulty >= 7 ? 'Advanced Exercise - Focus on Form' : null,
              ))
          .toList(),
      accessories: accs
          .map((x) => WorkoutExercise(
                id: x.id,
                name: x.name,
                sets: prog['setsAcc'],
                reps: repAcc,
                rest: prog['restAcc'],
              ))
          .toList(),
      note: note,
    ));
  }

  return WorkoutPlan(
    meta: {
      'level': level,
      'days': days,
      'goal': goal,
      'week': week,
      'adherence': adherence,
      'rpe': rpe,
      'equipment': equipment,
      'injuries': injuries.map((i) => {'type': i.type, 'severity': i.severity}).toList(),
    },
    plan: daysOut,
    muscleGroupVolume: muscleGroupVolume,
  );
}