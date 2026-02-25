import sys
import os
import json
import time
from redis.cluster import RedisCluster, ClusterNode
from google.cloud import bigtable


def fetch_from_valkey(ip, port, email):
    startup_nodes = [ClusterNode(ip, int(port))]
    rc = RedisCluster(startup_nodes=startup_nodes, decode_responses=True)
    rc.ping()  # make sure we're running on a hot connection
    start_time = time.perf_counter()
    pipe = rc.pipeline()
    pipe.hgetall("{{{}}}:profile".format(email))
    pipe.hgetall("{{{}}}:purchases".format(email))
    pipe.hgetall("{{{}}}:intent".format(email))
    res = pipe.execute()
    elapsed_time = (time.perf_counter() - start_time) * 1000
    if len(res[0]) > 0:
        print(
            json.dumps(
                {
                    "profile": res[0],
                    "purchases": res[1],
                    "intent": res[2],
                    "fetch_time": f"{elapsed_time:.2f} ms",
                    "source": "valkey",
                }
            )
        )
    else:
        get_user_info(
            user_email, project_id, suffix, "profiles"
        )  # just fetch for a hot connection
        start_time = time.perf_counter()
        profile = get_user_info(user_email, project_id, suffix, "profiles")
        purchases = get_user_info(user_email, project_id, suffix, "purchases")
        elapsed_time = (time.perf_counter() - start_time) * 1000
        print(
            json.dumps(
                {
                    "fetch_time": f"{elapsed_time:.2f} ms",
                    "soruce": "bigtable",
                    "profile": profile,
                    "purchases": purchases,
                    "intent": {},
                }
            )
        )


def get_user_info(email, project_id, suffix, ltype):
    return_data = {}
    client = bigtable.Client(project=project_id, admin=True)
    instance = client.instance("bt-i-{}".format(suffix))
    table = instance.table("bt-t-{}-{}".format(ltype, suffix))

    # Fetch the row using the email as the row key
    row_key = email.encode("utf-8")
    row = table.read_row(row_key)

    if not row:
        return return_data

    # Access the 'profile' column family
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
            # Bigtable stores values as bytes; decoding them back to string/float
            value = cells[0].value.decode("utf-8")
            return_data[column_name] = value
    return return_data


if __name__ == "__main__":
    project_id = os.getenv("BIGTABLE_PROJECT", "mague-tf")
    suffix = os.getenv("BIGTABLE_SUFFIX", "playnice")
    memorystore_ip = os.getenv("MEMORYSTORE_IP", "192.168.68.111")
    memorystore_port = os.getenv("MEMORYSTORE_PORT", "30001")
    if len(sys.argv) < 2:
        print("Usage: uv run get_user_profile.py <email>")
    else:
        user_email = sys.argv[1]
        fetch_from_valkey(memorystore_ip, memorystore_port, user_email)
