"""Regression tests for conservative routing and attention lifecycle."""

import collections
from pathlib import Path
import runpy
import unittest
from unittest.mock import patch


MODULE = runpy.run_path(str(Path(__file__).parents[1] / "files/notification-workspaces"))
resolve = MODULE["resolve_source"]
Bridge = MODULE["Bridge"]
identity = MODULE["identity"]


def window(address="0x123", pid=100, workspace=2, stable="1", app="editor"):
    return {"address": address, "pid": pid, "stableId": stable, "mapped": True,
            "class": app, "initialClass": app, "workspace": {"id": workspace},
            "pinned": False}


class RoutingTests(unittest.TestCase):
    def test_terminal_descendant(self):
        terminal = window(app="foot", pid=100)
        self.assertEqual(resolve("build", {}, [300, 200, 100], [terminal], {}), identity(terminal))

    def test_two_windows_from_same_process_are_ambiguous(self):
        windows = [window(), window("0x456", workspace=3, stable="2")]
        self.assertIsNone(resolve("editor", {}, [100], windows, {}))

    def test_desktop_identity_overrides_unrelated_sender_ancestry(self):
        terminal = window(pid=100, app="foot")
        browser = window("0x456", 200, stable="2", app="zen")
        self.assertEqual(resolve("test", {"desktop-entry": "zen"}, [100],
                                 [terminal, browser], {}), identity(browser))

    def test_desktop_startup_class_alias(self):
        browser = window(app="zen")
        self.assertEqual(resolve("Zen Browser", {"desktop-entry": "app.zen_browser.zen"},
                                 [], [browser], {"app.zen_browser.zen": {"zen"}}), identity(browser))

    def test_unknown_source_never_uses_focused_window(self):
        self.assertIsNone(resolve("unknown", {}, [], [window()], {}))

    def test_multiwindow_class_is_not_guessed(self):
        self.assertIsNone(resolve("editor", {}, [], [window(), window("0x456", 200)], {}))


class LifecycleTests(unittest.TestCase):
    def setUp(self):
        self.bridge = Bridge.__new__(Bridge)
        self.bridge.refresh_source = None
        self.bridge.pending = set()
        self.bridge.notifications = collections.OrderedDict()
        self.bridge.write_css = lambda value: setattr(self.bridge, "css", value)
        self.workspaces = [{"id": 1, "monitor": "eDP-1"}, {"id": 2, "monitor": "eDP-1"},
                           {"id": 3, "monitor": "DP-2"}]
        self.windows = [window()]
        self.active = 1
        self.special = 0
        self.globals = Bridge.refresh.__globals__

    def query(self, command):
        return {"clients": self.windows, "workspaces": self.workspaces,
                "monitors": [{"focused": True, "activeWorkspace": {"id": self.active},
                              "specialWorkspace": {"id": self.special}}]}[command]

    def refresh(self):
        with patch.dict(self.globals, hypr=self.query):
            self.bridge.refresh()

    def test_attention_survives_expiry_until_visit(self):
        key = identity(self.windows[0])
        self.bridge.pending.add(key)
        self.refresh()
        self.assertIn("nth-child(2)", self.bridge.css)
        self.bridge.notifications.clear()  # Notification lifetime is independent.
        self.refresh()
        self.assertIn(key, self.bridge.pending)
        self.active = 2
        self.refresh()
        self.assertFalse(self.bridge.pending)
        self.assertNotIn("nth-child", self.bridge.css)

    def test_move_between_outputs_and_close(self):
        self.bridge.pending.add(identity(self.windows[0]))
        self.windows[0]["workspace"]["id"] = 3
        self.refresh()
        self.assertIn("nth-child(1)", self.bridge.css)
        self.assertIn("\\44 \\50 \\2d \\32 ", self.bridge.css)
        self.windows.clear()
        self.refresh()
        self.assertFalse(self.bridge.pending)

    def test_hidden_magic_does_not_shift_attention_buttons(self):
        self.workspaces.append({"id": -98, "name": "special:magic", "monitor": "eDP-1"})
        self.windows.append(window("0x456", 200, -98, "2"))
        self.bridge.pending.update(map(identity, self.windows))
        self.refresh()
        self.assertIn("nth-child(2)", self.bridge.css)
        self.assertEqual(self.bridge.css.count("nth-child"), 1)

    def test_address_reuse_cannot_focus_replacement_window(self):
        self.bridge.notifications[5] = identity(self.windows[0])
        self.windows[0]["stableId"] = "2"
        with patch.dict(self.globals, hypr=self.query), patch("subprocess.run") as run:
            self.bridge.focus(5)
            run.assert_not_called()

    def test_click_uses_window_address_after_workspace_move(self):
        self.bridge.notifications[5] = identity(self.windows[0])
        self.windows[0]["workspace"]["id"] = 3
        self.bridge.schedule_refresh = lambda: None
        with patch.dict(self.globals, hypr=self.query), patch("subprocess.run") as run:
            self.bridge.focus(5)
            self.assertEqual(run.call_args.args[0],
                             ["hyprctl", "eval", 'hl.dispatch(hl.dsp.focus({window="address:0x123"}))'])

    def test_special_workspace_visit_and_pinned_window(self):
        self.windows[0]["workspace"]["id"] = -98
        self.special = -98
        self.bridge.pending.add(identity(self.windows[0]))
        self.refresh()
        self.assertFalse(self.bridge.pending)
        self.special = 0
        self.windows[0]["pinned"] = True
        self.bridge.pending.add(identity(self.windows[0]))
        self.refresh()
        self.assertFalse(self.bridge.pending)

    def test_multiple_sources_clear_only_visited_workspace(self):
        self.windows.append(window("0x456", 200, 3, "2"))
        self.bridge.pending.update(map(identity, self.windows))
        self.active = 2
        self.refresh()
        self.assertEqual(self.bridge.pending, {identity(self.windows[1])})


if __name__ == "__main__":
    unittest.main()
