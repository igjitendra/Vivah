import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppShortcut {
  tab1,
  tab2,
  tab3,
  tab4,
  tab5,
  newEntry,
  search,
  settings,
  shortcutsHelp,
  escape,
}

/// PC Desktop Keyboard Shortcuts Service directly adapted from InlitX/streak
class AppShortcuts {
  AppShortcuts._();

  static bool _installed = false;
  static final List<Function(AppShortcut)> _listeners = [];

  static void install() {
    if (_installed) return;
    _installed = true;
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  static void dispose() {
    if (!_installed) return;
    HardwareKeyboard.instance.removeHandler(_onKey);
    _installed = false;
    _listeners.clear();
  }

  static void addListener(Function(AppShortcut) listener) {
    _listeners.add(listener);
  }

  static void removeListener(Function(AppShortcut) listener) {
    _listeners.remove(listener);
  }

  static void _dispatch(AppShortcut shortcut) {
    for (final listener in List.of(_listeners)) {
      listener(shortcut);
    }
  }

  static bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final keys = HardwareKeyboard.instance;
    final isMac = Platform.isMacOS;
    final primary = isMac ? keys.isMetaPressed : keys.isControlPressed;
    final alt = keys.isAltPressed;
    final key = event.logicalKey;

    // F1 or Ctrl+/ -> Shortcuts Help
    if (key == LogicalKeyboardKey.f1 || (primary && key == LogicalKeyboardKey.slash)) {
      _dispatch(AppShortcut.shortcutsHelp);
      return true;
    }

    // Escape -> Pop / Dismiss
    if (key == LogicalKeyboardKey.escape && !primary && !alt) {
      _dispatch(AppShortcut.escape);
      return true;
    }

    // Ctrl + 1..5 -> Switch Tabs
    if (primary && !alt) {
      if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
        _dispatch(AppShortcut.tab1);
        return true;
      }
      if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
        _dispatch(AppShortcut.tab2);
        return true;
      }
      if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
        _dispatch(AppShortcut.tab3);
        return true;
      }
      if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
        _dispatch(AppShortcut.tab4);
        return true;
      }
      if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
        _dispatch(AppShortcut.tab5);
        return true;
      }

      // Ctrl + N -> New Transaction
      if (key == LogicalKeyboardKey.keyN) {
        _dispatch(AppShortcut.newEntry);
        return true;
      }

      // Ctrl + F -> Search
      if (key == LogicalKeyboardKey.keyF) {
        _dispatch(AppShortcut.search);
        return true;
      }

      // Ctrl + , -> Settings
      if (key == LogicalKeyboardKey.comma) {
        _dispatch(AppShortcut.settings);
        return true;
      }
    }

    return false;
  }
}
