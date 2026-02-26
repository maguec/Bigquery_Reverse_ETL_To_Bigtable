import sys
import json
import time
from redis.cluster import RedisCluster, ClusterNode
from google.cloud import bigtable


def _get_user_info(email, project_id, suffix, ltype):
    """Private helper to fetch a specific column family from Bigtable."""
    return_data = {}
    client = bigtable.Client(project=project_id, admin=True)
    instance = client.instance("bt-i-{}".format(suffix))
    table = instance.table("bt-t-{}-{}".format(ltype, suffix))

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


def fetch_from_valkey(ip, port, email):
    """Fetches user profile, purchases, and intent from Valkey (RedisCluster)."""
    startup_nodes = [ClusterNode(ip, int(port))]
    rc = RedisCluster(startup_nodes=startup_nodes, decode_responses=True)
    rc.ping()

    start_time = time.perf_counter()
    pipe = rc.pipeline()
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


def fetch_from_bigtable(email, project_id, suffix):
    """Fetches user profile and purchases from Bigtable."""
    start_time = time.perf_counter()
    profile = _get_user_info(email, project_id, suffix, "profiles")
    purchases = _get_user_info(email, project_id, suffix, "purchases")
    elapsed_time = (time.perf_counter() - start_time) * 1000

    return {
        "fetch_time": f"{elapsed_time:.2f} ms",
        "source": "bigtable",
        "profile": profile,
        "purchases": purchases,
        "intent": {},
    }


def get_profile_with_fallback(ip, port, email, project_id, suffix):
    """Tries fetching from Valkey first, falling back to Bigtable if empty."""
    result = fetch_from_valkey(ip, port, email)

    if result is None:
        result = fetch_from_bigtable(email, project_id, suffix)

    print(json.dumps(result))
    return result


def write_dict_to_valkey(ip, port, key_name, data_dict):
    """Writes a dictionary to Valkey using a hash set."""
    if not data_dict:
        return

    startup_nodes = [ClusterNode(ip, int(port))]
    rc = RedisCluster(startup_nodes=startup_nodes, decode_responses=True)
    rc.hset(name=key_name, mapping={k: str(v) for k, v in data_dict.items()})


def cache_profile_to_valkey(ip, port, email, project_id, suffix):
    """Fetches profile and purchases from Bigtable and writes them to Valkey."""
    print("Fetching profile for user: {}".format(email))

    profile = _get_user_info(email, project_id, suffix, "profiles")
    purchases = _get_user_info(email, project_id, suffix, "purchases")

    if not profile and not purchases:
        print(f"No profile found for email: {email}")
        return

    print("Profile:")
    print(json.dumps(profile))
    print("Purchases:")
    print(json.dumps(purchases))
    print("Writing user data to Memorystore")

    if purchases:
        write_dict_to_valkey(
            ip, port, "{{{}}}:{}".format(email, "purchases"), purchases
        )
    if profile:
        write_dict_to_valkey(ip, port, "{{{}}}:{}".format(email, "profile"), profile)
