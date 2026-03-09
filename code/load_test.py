import sys
from profile_utils import FeatureStore
from alive_progress import alive_bar
from tabulate import tabulate
import numpy as np

if __name__ == "__main__":
    fs = FeatureStore()

    if len(sys.argv) < 2:
        print("Usage: uv run load_test.py <file>")
        sys.exit(1)

    with open(sys.argv[1], "r") as file:
        emails = [line.strip() for line in file if line.strip()]

    btstats = np.array([])
    msstats = np.array([])

    with alive_bar(len(emails)) as bar:
        for x in emails:
            bt = fs.get_profile_with_fallback(x, quiet=True)
            ms = fs.cache_profile_to_valkey(x, quiet=True)
            if bt["source"] == "bigtable":
                btstats = np.append(btstats, float(bt["fetch_time"].split()[0]))
            else:
                msstats = np.append(msstats, float(bt["fetch_time"].split()[0]))
            bt2 = fs.get_profile_with_fallback(x, quiet=True)
            if bt2["source"] == "bigtable":
                btstats = np.append(btstats, float(bt2["fetch_time"].split()[0]))
            else:
                msstats = np.append(msstats, float(bt2["fetch_time"].split()[0]))
            bar()

    headers = ["Stat", "Bigtable (ms)", "Memorystore (ms)"]
    # If everything comes from memorystore numpy gets angry
    if btstats.size > 0:
        bt_mean = btstats.mean()
        bt_p95 = np.percentile(btstats, 95)
        bt_p99 = np.percentile(btstats, 99)
    else:
        bt_mean = "Nan"
        bt_p95 = "Nan"
        bt_p99 = "Nan"
    data = [
        ["count", btstats.size, msstats.size],
        ["mean", bt_mean, msstats.mean()],
        ["p95", bt_p99, np.percentile(msstats, 95)],
        ["p99", bt_p99, np.percentile(msstats, 99)],
    ]
    print(tabulate(data, headers=headers, tablefmt="fancy_grid"))
