import unittest

from telegram_download import message_link, safe_name


class InputTests(unittest.TestCase):
    def test_private_link(self):
        self.assertEqual(message_link("https://t.me/c/1234567890/42"), (-1001234567890, 42))

    def test_topic_link_uses_message_id(self):
        self.assertEqual(message_link("https://t.me/c/1234567890/5/42?single"), (-1001234567890, 42))

    def test_public_link(self):
        self.assertEqual(message_link("https://t.me/example_channel/42"), ("example_channel", 42))

    def test_reject_invites_and_unrelated_urls(self):
        for link in ("https://t.me/+invite", "https://example.com/c/123/42", "https://t.me/c/123/no", "https://t.me/c/0/42"):
            with self.subTest(link=link), self.assertRaises(ValueError):
                message_link(link)

    def test_filename_cannot_escape_output_folder(self):
        name = safe_name('../../folder\\clip:one.mp4 ')
        self.assertNotIn("/", name)
        self.assertNotIn("\\", name)
        self.assertNotIn(":", name)
        self.assertFalse(name.endswith(" "))


if __name__ == "__main__":
    unittest.main()
