import os
import unittest
import urllib.request

from fixture import greeting


class FixtureTest(unittest.TestCase):
    def test_greeting(self):
        self.assertEqual(greeting("ProbeLab"), "Hello, ProbeLab")

    @unittest.skipUnless(os.environ.get("CLICKHOUSE_HTTP_PORT"), "CLICKHOUSE_HTTP_PORT is not set")
    def test_clickhouse(self):
        """The workflow started ClickHouse and gave the tests its ports."""
        url = f"http://{os.environ['CLICKHOUSE_HOST']}:{os.environ['CLICKHOUSE_HTTP_PORT']}/ping"
        with urllib.request.urlopen(url, timeout=10) as response:
            self.assertEqual(response.read().decode().strip(), "Ok.")


if __name__ == "__main__":
    unittest.main()
