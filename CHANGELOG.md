# Changelog

## 0.1.1 — 2026-10-17

- Fix title dragging starting only after the mouse was released. Use native
  Windows movement from mouse-down, including an initially unpinned panel.
- Make passive status requests asynchronous with one outstanding request and
  a two-second completion deadline outside active dragging.
- Defer meter painting, hover checks and position writes during movement;
  resume on release and save the final position once.
- Add sampled native drag checks and actual AHK status-transition tests,
  including timeout recovery and wrong-model/sleep/Ollama states.

## 0.1.0 — 2026-10-17

- Native meter icon with configurable VRAM/RAM/GPU rows and model status.
- Hover details, automatic hide, pin, drag and persisted panel position.
- Global AutoHotkey shortcut, notifications and native settings dialog.
- llama.cpp, existing Ollama daemon and trusted PowerShell launcher profiles.
- Exact-process ownership checks; passive polling; no model or boot autostart.
- Pinned installer, optional loopback SSH tunnels, Windows CI and setup guides.
- Extracted from Local Coding Lab's 0.5.0 controller; preserved owner safeguards.
