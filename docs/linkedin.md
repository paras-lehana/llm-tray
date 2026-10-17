---
platform: linkedin
project: llm-tray
source_idea: A small Windows tray meter and configurable local model controller
angle: tech build story
status: draft
version: 1.0
last_updated: 2026-10-17
char_count: 1145
published_url: ""
---

My local coding model was sharing a 10 GB GPU with everything else on my PC.
I wanted a small control beside the clock.

So I built LLM Tray: three tiny VRAM/RAM/GPU meter rows, a model-status dot, and exact numbers on hover. Pin the panel when debugging. Drag it away when it covers something.

Ctrl+Alt+L toggles the model. You can change that shortcut, hide metrics, and choose a llama.cpp, Ollama or custom PowerShell launcher. The installer does not download a model or start one at login.

One useful distinction: idle sleep can wake on the next request; manually stopping the server needs an explicit start. Neither preserves live KV forever. Your client still needs to send its chat history.

I tested the actual Windows tray interactions and connected two remote Linux hosts to the PC model through loopback SSH tunnels. This does not make a slow model faster. It makes its availability and memory use easier to control.

Code, setup guide and test limits:
https://github.com/paras-lehana/llm-tray

Which would you use more: automatic idle unloading or an explicit memory-release shortcut?

#LocalAI #OpenSource #Windows #DeveloperTools

### Add Project Details (For LinkedIn Profile)

Link: https://www.linkedin.com/in/paras-lehana/edit/forms/project/new/

Project name: LLM Tray

Description:

https://github.com/paras-lehana/llm-tray

- Native Windows notification-area resource meter and local model controller,
  built with AutoHotkey v2, Win32/NVML and PowerShell.

- Hover details, persistent pin/drag, configurable metrics and global shortcut,
  plus llama.cpp, Ollama and trusted custom-script profiles.

- Exact-process stop checks, passive sleep-aware monitoring, pinned runtime
  installation, loopback SSH access and automated behavior tests.

Top 5 skills applied: Windows automation, PowerShell, local inference,
software testing, developer experience.

Media: “Your model beside the clock” — tray icon and ready panel;
“Choose what matters” — native Settings dialog.
