# Let's fetch some profile information

## Fetch a profile from the backing store
```bash
uv run fetch_profile.py michaelrush@example.com 
```


## Log this user in and fetch their profile
```bash
uv run cache_profile.py michaelrush@example.com 
```


## Run again to see the difference in fetch time
```bash
uv run fetch_profile.py michaelrush@example.com 
```

## Add Intent to buy for an item of a logged in customer with a timeout of 20 seconds
```bash
uv run add_intent.py michaelrush@example.com sneakers 20
```

## Run the profile to see the intent time out
```bash
uv run fetch_profile.py michaelrush@example.com 
sleep 20
uv run fetch_profile.py michaelrush@example.com 
```
