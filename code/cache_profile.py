import sys
import os
import json
from redis.cluster import RedisCluster, ClusterNode
from google.cloud import bigtable


def write_dict_to_valkey(ip, port, key_name, data_dict):

    startup_nodes = [ClusterNode(ip, int(port))]
    rc = RedisCluster(startup_nodes=startup_nodes, decode_responses=True)
    rc.hset(name=key_name, mapping={k: str(v) for k, v in data_dict.items()})


def get_user_info(email, project_id, suffix, ltype):
    return_data = {}
    client = bigtable.Client(project=project_id, admin=True)
    instance = client.instance("bt-i-{}".format(suffix))
    table = instance.table("bt-t-{}-{}".format(ltype, suffix))

    # Fetch the row using the email as the row key
    row_key = email.encode("utf-8")
    row = table.read_row(row_key)

    if not row:
        print(f"No profile found for email: {email}")
        return

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
        print("Fetching profile for user: {}".format(user_email))
        profile = get_user_info(user_email, project_id, suffix, "profiles")
        purchases = get_user_info(user_email, project_id, suffix, "purchases")
        print("Profile:")
        print(json.dumps(profile))
        print("Purchases:")
        print(json.dumps(purchases))
        print("Writing user data to Memorystore")
        write_dict_to_valkey(
            memorystore_ip,
            memorystore_port,
            "{{{}}}:{}".format(user_email, "purchases"),
            purchases,
        )
        write_dict_to_valkey(
            memorystore_ip,
            memorystore_port,
            "{{{}}}:{}".format(user_email, "profile"),
            profile,
        )
