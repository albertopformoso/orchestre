import json
from pathlib import Path
import runpy
import tempfile
import unittest
from unittest.mock import patch


MODULE = runpy.run_path(str(Path(__file__).parents[1] / "files/battery-notifications"))
transition = MODULE["transition"]


class BatteryTests(unittest.TestCase):
    def test_discharge_crosses_each_threshold_once(self):
        state = {}
        events = []
        for capacity in (50, 30, 30, 29, 16, 15, 15, 14):
            state, event = transition(state, capacity, False)
            if event:
                events.append(event)
        self.assertEqual(events, ["warning", "critical"])

    def test_starting_critical_does_not_also_warn(self):
        state, event = transition({}, 10, False)
        self.assertEqual(event, "critical")
        self.assertIsNone(transition(state, 10, False)[1])

    def test_full_survives_restart_and_charge_chatter(self):
        state, event = transition({}, 100, True)
        self.assertEqual(event, "full")
        state = json.loads(json.dumps(state))  # Reload persisted state.
        for capacity, powered in ((100, True), (99, True), (100, True), (100, False), (100, True)):
            state, event = transition(state, capacity, powered)
            self.assertIsNone(event)
        state, _ = transition(state, 95, False)
        self.assertEqual(transition(state, 100, True)[1], "full")

    def test_charging_rearms_low_alerts(self):
        state, _ = transition({}, 10, False)
        state, event = transition(state, 10, True)
        self.assertIsNone(event)
        self.assertEqual(transition(state, 10, False)[1], "critical")

    def test_threshold_noise_does_not_repeat(self):
        state, _ = transition({}, 30, False)
        for capacity in (31, 30, 32, 30, 33, 30):
            state, event = transition(state, capacity, False)
            self.assertIsNone(event)
        state, _ = transition(state, 34, False)
        self.assertEqual(transition(state, 30, False)[1], "warning")

    def test_reading_ignores_peripherals_and_honors_ac(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name, values in {
                "BAT0": {"type": "Battery", "capacity": "100", "status": "Not charging"},
                "mouse": {"type": "Battery", "scope": "Device", "capacity": "5"},
                "AC": {"type": "Mains", "online": "1"},
            }.items():
                (root / name).mkdir()
                for key, value in values.items():
                    (root / name / key).write_text(value)
            self.assertEqual(MODULE["read_battery"](root), (100, True))

    def test_low_alerts_keep_sound_category(self):
        with patch("subprocess.run") as run:
            for event in ("warning", "critical"):
                MODULE["notify"](event)
                command = run.call_args.args[0]
                self.assertEqual(command[command.index("-c") + 1], "device.battery.low")
            MODULE["notify"]("full")
            self.assertNotIn("-c", run.call_args.args[0])


if __name__ == "__main__":
    unittest.main()
