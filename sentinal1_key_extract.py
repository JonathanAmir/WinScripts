#This script extracts the ID, Hostname, Domain and Passphrase for SentinalOne agents.
#Required additional packages: requests
# Disclaimer
#This script is provided "as-is" and is intended for free public use. By using this script, you acknowledge that you do so at your own discretion and risk. The author of this script assumes no responsibility for any consequences, damages, or issues that may arise from its use, including but not limited to data loss, security breaches, or system malfunctions. 
#You are encouraged to thoroughly review and test the script in your environment before deployment. Use it responsibly, and modify it as needed to suit your specific requirements.
#This script was created with the assistance of Copilot and Gemini

#Required arguemnts: "url" "-o <outputfile>"


import argparse
import csv
import requests
from typing import Generator

# Constants
HEADERS = {
    "Accept": "application/json",
    "User-Agent": "vz/s1_agent_passphrases_v1.0",
    "Content-Type": "application/json",
}
S1_PASSPHRASE_API_ENDPOINT = "/web/api/v2.1/agents/passphrases"
#More fields can be added. If added, remember to include them in the YIELD
FIELDS = ["id", "computerName", "domain", "passphrase"] 
LIMIT = 200

# Hardcoded values
SITE_IDS = "123"  # Replace with actual site IDs
API_KEY = "123" # Replace with actual API key

def result_generator(base_url: str) -> Generator[dict, None, None]:
    """Fetch and yield passphrase data from SentinelOne API."""
    headers = {**HEADERS, "Authorization": f"ApiToken {API_KEY}"}
    url = f"{base_url}{S1_PASSPHRASE_API_ENDPOINT}"
    params = {"limit": LIMIT, "siteIds": SITE_IDS.split(",")}
    next_cursor, done, errored = None, False, False

    while not (done or errored):
        if next_cursor:
            params["cursor"] = next_cursor

        try:
            response = requests.get(url, headers=headers, params=params)
            response.raise_for_status()
            data = response.json()

            next_cursor = data.get("pagination", {}).get("nextCursor")
            done = next_cursor is None

            if "data" in data:
                for item in data["data"]:
                    yield {k: item.get(k, "") for k in FIELDS}  # Extract all fields, including 'id'
            else:
                errored = True
                print("Error parsing data:", data.get("errors", "Unknown error"))

        except requests.exceptions.RequestException as e:
            errored = True
            print(f"Request failed: {e}")

def main():
    parser = argparse.ArgumentParser(description="Query SentinelOne API, return agent passphrases as CSV.")
    parser.add_argument("url", help="Base API URL")
    parser.add_argument("--output_file", "-o", help="Output filename (default: output.csv)", default="output.csv")

    args = parser.parse_args()

    try:
        with open(args.output_file, "w", newline="", encoding="utf-8") as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=FIELDS)
            writer.writeheader()

            for line in result_generator(args.url):
                writer.writerow(line)

        print(f"Data successfully saved to {args.output_file}")

    except IOError as e:
        print(f"File writing error: {e}")

if __name__ == "__main__":
    main()
