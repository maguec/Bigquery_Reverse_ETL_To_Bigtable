import sys
import os
from redis.cluster import RedisCluster, ClusterNode


def write_dict_to_valkey(ip, port, key_name, item, ttl):

    startup_nodes = [ClusterNode(ip, int(port))]
    rc = RedisCluster(startup_nodes=startup_nodes, decode_responses=True)
    rc.hset(name=key_name, mapping={item: 1})
    rc.execute_command("HEXPIRE", key_name, ttl, "FIELDS", "1", item)


if __name__ == "__main__":
    memorystore_ip = os.getenv("MEMORYSTORE_IP", "192.168.68.111")
    memorystore_port = os.getenv("MEMORYSTORE_PORT", "30001")
    if len(sys.argv) < 4:
        print("Usage: uv run get_user_profile.py <email> item TTL")
    else:
        user_email = sys.argv[1]
        item = sys.argv[2]
        ttl = sys.argv[3]
        write_dict_to_valkey(
            memorystore_ip,
            memorystore_port,
            "{{{}}}:{}".format(user_email, "intent"),
            item,
            ttl,
        )
