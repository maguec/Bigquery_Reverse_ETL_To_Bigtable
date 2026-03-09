import sys
import os
from profile_utils import FeatureStore

if __name__ == "__main__":

    fs = FeatureStore()

    if len(sys.argv) < 2:
        print("Usage: uv run fetch_profile.py <email>")
    else:
        user_email = sys.argv[1]
        fs.get_profile_with_fallback(user_email)
