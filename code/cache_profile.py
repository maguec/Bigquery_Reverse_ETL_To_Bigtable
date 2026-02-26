import sys
import os
from profile_utils import cache_profile_to_valkey

if __name__ == "__main__":
    project_id = os.getenv("BIGTABLE_PROJECT", "mague-tf")
    suffix = os.getenv("BIGTABLE_SUFFIX", "playnice")
    memorystore_ip = os.getenv("MEMORYSTORE_IP", "192.168.68.111")
    memorystore_port = os.getenv("MEMORYSTORE_PORT", "30001")

    if len(sys.argv) < 2:
        print("Usage: uv run cache_profile.py <email>")
    else:
        user_email = sys.argv[1]
        cache_profile_to_valkey(
            memorystore_ip, memorystore_port, user_email, project_id, suffix
        )
