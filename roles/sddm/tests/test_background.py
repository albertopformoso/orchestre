"""Run with: python3 -m unittest discover -s roles/sddm/tests -v"""

import io
from pathlib import Path
import runpy
import tempfile
import unittest
from unittest.mock import patch


HELPER = Path(__file__).resolve().parents[1] / "files/scripts/orchestre-sddm-background"
PNG = b"\x89PNG\r\n\x1a\nexample payload"


class BackgroundTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.background = Path(self.directory.name) / "background.png"
        self.background.write_bytes(b"previous wallpaper")
        self.publish = runpy.run_path(str(HELPER))["publish"]
        self.publish.__globals__["BACKGROUND"] = self.background

    def test_publish_replaces_file_with_readable_copy(self):
        previous_inode = self.background.stat().st_ino
        self.publish(io.BytesIO(PNG))
        self.assertEqual(self.background.read_bytes(), PNG)
        self.assertEqual(self.background.stat().st_mode & 0o777, 0o644)
        self.assertNotEqual(self.background.stat().st_ino, previous_inode)
        self.assertEqual(list(self.background.parent.iterdir()), [self.background])

    def test_empty_and_non_png_input_preserve_previous_wallpaper(self):
        for data in (b"", b"not an image"):
            with self.subTest(data=data), self.assertRaises(ValueError):
                self.publish(io.BytesIO(data))
            self.assertEqual(self.background.read_bytes(), b"previous wallpaper")

    def test_oversized_input_preserves_previous_wallpaper(self):
        self.publish.__globals__["MAX_BYTES"] = len(PNG) - 1
        with self.assertRaises(ValueError):
            self.publish(io.BytesIO(PNG))
        self.assertEqual(self.background.read_bytes(), b"previous wallpaper")

    def test_failed_replace_preserves_wallpaper_and_removes_temporary_file(self):
        with patch("os.replace", side_effect=OSError("disk error")):
            with self.assertRaises(OSError):
                self.publish(io.BytesIO(PNG))
        self.assertEqual(self.background.read_bytes(), b"previous wallpaper")
        self.assertEqual(list(self.background.parent.iterdir()), [self.background])

    def test_destination_symlink_is_replaced_not_followed(self):
        other = self.background.parent / "other"
        other.write_bytes(b"do not overwrite")
        self.background.unlink()
        self.background.symlink_to(other)
        self.publish(io.BytesIO(PNG))
        self.assertFalse(self.background.is_symlink())
        self.assertEqual(other.read_bytes(), b"do not overwrite")
        self.assertEqual(self.background.read_bytes(), PNG)


if __name__ == "__main__":
    unittest.main()
