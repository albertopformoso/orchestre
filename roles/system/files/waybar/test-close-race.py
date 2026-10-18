#!/usr/bin/env python3
"""Exercise the actual close handler without a compositor or GTK event loop.

Usage: python3 test-close-race.py /path/to/patched/Waybar
The unpatched source fails the short-lived-window assertion.
"""
from pathlib import Path
import subprocess
import sys
import tempfile

source = (Path(sys.argv[1]) / "src/modules/hyprland/workspaces.cpp").read_text()
start = source.index("void Workspaces::onWindowClosed(")
handler = source[start:source.index("\n}", start) + 2]
stubs = r'''
#include <algorithm>
#include <cassert>
#include <map>
#include <memory>
#include <string>
#include <vector>
namespace spdlog { template<class... T> void trace(T...) {} }
struct Pending {
  std::string address;
  const std::string& getAddress() const { return address; }
};
struct Workspace {
  std::vector<std::string> icons;
  bool closeWindow(const std::string& address) { return std::erase(icons, address) > 0; }
};
struct Workspaces {
  std::vector<Pending> m_windowsToCreate;
  std::map<std::string, int> m_orphanWindowMap;
  std::vector<std::shared_ptr<Workspace>> m_workspaces;
  void updateWindowCount() {}
  void onWindowClosed(const std::string&);
};
'''
test = r'''
int main() {
  Workspaces workspaces;
  auto workspace = std::make_shared<Workspace>();
  workspaces.m_workspaces.push_back(workspace);
  workspaces.m_windowsToCreate = {{"dialog"}, {"game"}, {"dialog"}};
  workspaces.m_orphanWindowMap["dialog"] = 1;
  workspaces.onWindowClosed("dialog");
  // Simulate the UI draining the queue after receiving the close event.
  for (auto& pending : workspaces.m_windowsToCreate)
    workspace->icons.push_back(pending.address);
  assert(workspace->icons == std::vector<std::string>{"game"});
  assert(workspaces.m_orphanWindowMap.empty());
  workspaces.m_windowsToCreate.clear();
  workspaces.onWindowClosed("game");
  assert(workspace->icons.empty());
  workspaces.onWindowClosed("unknown");
}
'''
with tempfile.TemporaryDirectory() as directory:
    binary = str(Path(directory) / "close-race")
    subprocess.run(["c++", "-std=c++20", "-x", "c++", "-o", binary, "-"],
                   input=stubs + handler + test, text=True, check=True)
    subprocess.run([binary], check=True)
print("Pending close, duplicate pending entries, orphan cleanup, and normal close passed")
