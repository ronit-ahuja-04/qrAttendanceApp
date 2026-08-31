import 'package:flutter/material.dart';

class SubjectIcons {
  /// Returns a highly relevant Material Icon based on the standard Information Technology 
  /// curriculum subjects at Mumbai University (B.Sc IT / B.Tech IT).
  static IconData getIconForSubject(String subjectName) {
    final lower = subjectName.toLowerCase();
    
    // Programming / Dev
    if (lower.contains('programming') || lower.contains('c++')) return Icons.code;
    if (lower.contains('java') || lower.contains('oop') || lower.contains('object oriented')) return Icons.data_object;
    if (lower.contains('python')) return Icons.integration_instructions;
    if (lower.contains('web')) return Icons.language;
    if (lower.contains('mobile') || lower.contains('android') || lower.contains('ios')) return Icons.smartphone;
    if (lower.contains('software engineering')) return Icons.engineering;
    if (lower.contains('testing') || lower.contains('quality')) return Icons.bug_report;

    // Systems & Hardware
    if (lower.contains('operating system') || lower.contains('os') || lower.contains('linux')) return Icons.terminal;
    if (lower.contains('digital electronics') || lower.contains('microprocessor') || lower.contains('embedded')) return Icons.developer_board;
    if (lower.contains('architecture') || lower.contains('organization')) return Icons.memory;

    // Networks & Security
    if (lower.contains('network')) return Icons.router;
    if (lower.contains('security') || lower.contains('cryptography')) return Icons.security;
    if (lower.contains('iot') || lower.contains('internet of things')) return Icons.wifi_tethering;

    // Data & AI
    if (lower.contains('database') || lower.contains('dbms') || lower.contains('sql')) return Icons.storage;
    if (lower.contains('data structure') || lower.contains('algorithm')) return Icons.account_tree;
    if (lower.contains('data warehouse') || lower.contains('data mining')) return Icons.inventory_2;
    if (lower.contains('machine learning') || lower.contains('ml')) return Icons.model_training;
    if (lower.contains('artificial intelligence') || lower.contains('ai')) return Icons.psychology;
    if (lower.contains('business intelligence')) return Icons.insights;

    // Math & Theory
    if (lower.contains('math') || lower.contains('numerical') || lower.contains('discrete')) return Icons.calculate;
    if (lower.contains('statistics')) return Icons.bar_chart;

    // Graphics & MISC
    if (lower.contains('graphic') || lower.contains('animation')) return Icons.animation;
    if (lower.contains('gis') || lower.contains('geographic')) return Icons.map;
    if (lower.contains('management') || lower.contains('service')) return Icons.support_agent;
    if (lower.contains('communication')) return Icons.record_voice_over;

    // Default Fallback
    return Icons.menu_book;
  }
}
