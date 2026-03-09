import sys
from profile_utils import FeatureStore

if __name__ == "__main__":
    fs = FeatureStore()

    if len(sys.argv) < 2:
        print("Usage: uv run cache_profile.py <email>")
    else:
        user_email = sys.argv[1]
        fs.cache_profile_to_valkey(user_email)
