import re

path = "app/lib/ams/models.dart"
with open(path, "r") as f:
    code = f.read()

replacement = """
    String? pfp = json['profilePictureUrl'];
    if (pfp != null) {
      if (pfp.startsWith('/')) {
        pfp = 'https://qr-attendance-api-wvvs.onrender.com$pfp';
      } else if (pfp.contains('localhost:3000')) {
        pfp = pfp.replaceAll('http://localhost:3000', 'https://qr-attendance-api-wvvs.onrender.com');
      }
    }
"""

code = re.sub(
    r"String\? pfp = json\['profilePictureUrl'\];\s*if \(pfp != null && pfp\.startsWith\('/'\)\) \{\s*pfp = 'https://qr-attendance-api-wvvs\.onrender\.com\$pfp';\s*\}",
    replacement.strip(),
    code
)

with open(path, "w") as f:
    f.write(code)

print("Fixed models.dart")
