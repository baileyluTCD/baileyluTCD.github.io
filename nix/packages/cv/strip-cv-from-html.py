import sys
from bs4 import BeautifulSoup

if len(sys.argv) < 3:
    print("Usage: python script.py input.html output.html")
    sys.exit(1)

with open(sys.argv[1], "r") as f:
    input_html = f.read()

soup = BeautifulSoup(input_html, "html.parser")
cv_body = soup.select_one("#cv-body")

with open(sys.argv[2], "w") as f:
    f.write(cv_body.prettify())

print("Successfully wrote stripped CV HTML to file.")
