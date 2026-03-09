import sys
import os
import json
import time
from redis.cluster import RedisCluster, ClusterNode
from google.cloud import bigtable


class FeatureStore:

    def __init__(self):
        self.project_id = os.getenv("BIGTABLE_PROJECT", "mague-tf")
        self.suffix = os.getenv("BIGTABLE_SUFFIX", "playnice")
        self.ip = os.getenv("MEMORYSTORE_IP", "192.168.68.111")
        self.port = os.getenv("MEMORYSTORE_PORT", "30001")
        client = bigtable.Client(project=self.project_id, admin=True)
        self.instance = client.instance("bt-i-{}".format(self.suffix))

        """Fetches user profile, purchases, and intent from Valkey (RedisCluster)."""
        startup_nodes = [ClusterNode(self.ip, int(self.port))]
        self.rc = RedisCluster(startup_nodes=startup_nodes, decode_responses=True)
        self.rc.ping()

    def _get_user_info(self, email, ltype):
        """Private helper to fetch a specific column family from Bigtable."""
        return_data = {}
        table = self.instance.table("bt-t-{}-{}".format(ltype, self.suffix))

        row_key = email.encode("utf-8")
        row = table.read_row(row_key)

        if not row:
            return return_data

        if ltype == "profiles":
            family_id = "profile"
        elif ltype == "purchases":
            family_id = "purchases"
        else:
            print("error determining lookup type")
            sys.exit(1)

        if family_id in row.cells:
            for column, cells in row.cells[family_id].items():
                column_name = column.decode("utf-8")
                value = cells[0].value.decode("utf-8")
                return_data[column_name] = value

        return return_data

    def fetch_from_valkey(self, email):

        start_time = time.perf_counter()
        pipe = self.rc.pipeline()
        pipe.hgetall("{{{}}}:profile".format(email))
        pipe.hgetall("{{{}}}:purchases".format(email))
        pipe.hgetall("{{{}}}:intent".format(email))
        res = pipe.execute()
        elapsed_time = (time.perf_counter() - start_time) * 1000

        if len(res[0]) > 0:
            return {
                "profile": res[0],
                "purchases": res[1],
                "intent": res[2],
                "fetch_time": f"{elapsed_time:.2f} ms",
                "source": "valkey",
            }
        return None

    def fetch_from_bigtable(self, email):
        """Fetches user profile and purchases from Bigtable."""
        start_time = time.perf_counter()
        profile = self._get_user_info(email, "profiles")
        purchases = self._get_user_info(email, "purchases")
        elapsed_time = (time.perf_counter() - start_time) * 1000

        return {
            "fetch_time": f"{elapsed_time:.2f} ms",
            "source": "bigtable",
            "profile": profile,
            "purchases": purchases,
            "intent": {},
        }

    def get_profile_with_fallback(self, email, quiet=False):
        """Tries fetching from Valkey first, falling back to Bigtable if empty."""
        result = self.fetch_from_valkey(email)

        if result is None:
            result = self.fetch_from_bigtable(email)

        if not quiet:
            print(json.dumps(result))
        return result

    def write_dict_to_valkey(self, key_name, data_dict):
        """Writes a dictionary to Valkey using a hash set."""
        if not data_dict:
            return

        self.rc.hset(name=key_name, mapping={k: str(v) for k, v in data_dict.items()})

    def cache_profile_to_valkey(self, email, quiet=False):
        """Fetches profile and purchases from Bigtable and writes them to Valkey."""
        if not quiet:
            print("Fetching profile for user: {}".format(email))

        profile = self._get_user_info(email, "profiles")
        purchases = self._get_user_info(email, "purchases")

        if not profile and not purchases:
            print(f"No profile found for email: {email}")
            return

        if not quiet:
            print("Profile:")
            print(json.dumps(profile))
            print("Purchases:")
            print(json.dumps(purchases))
            print("Writing user data to Memorystore")

        if purchases:
            self.write_dict_to_valkey("{{{}}}:{}".format(email, "purchases"), purchases)
        if profile:
            self.write_dict_to_valkey("{{{}}}:{}".format(email, "profile"), profile)
