# My Pi-hole Blocklist

A curated, deduplicated blocklist built from trusted upstream sources, with a
whitelist applied to avoid common false-positive breakage (payment processors,
CDNs, login flows, streaming).

## How it works

- `sources.txt` — the upstream blocklists that get merged
- `whitelist.txt` — domains explicitly excluded even if an upstream list blocks them
- `build.sh` — fetches all sources, merges, deduplicates, strips whitelisted domains,
  and writes the final `hosts.txt`
- `.github/workflows/build.yml` — runs `build.sh` daily via GitHub Actions and
  commits the updated `hosts.txt` automatically

## Using this in Pi-hole

1. Push this repo to your own GitHub account
2. In Pi-hole admin UI: **Group Management → Adlists**
3. Add this URL (replace `yourusername`):
   ```
   https://raw.githubusercontent.com/yourusername/pihole-blocklist/main/hosts.txt
   ```
4. Update gravity:
   ```bash
   pihole -g
   ```

## Maintaining it

- If a site breaks, check Pi-hole's **Query Log**, find the blocked domain,
  add it to `whitelist.txt`, commit/push — the next scheduled build (or a
  manual "Run workflow" trigger in the Actions tab) will exclude it.
- To add more upstream sources, add a URL to `sources.txt` on its own line.
- To rebuild manually instead of waiting for the schedule:
  ```bash
  ./build.sh
  ```
