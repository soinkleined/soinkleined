"""Point a checked-out metrics action at the image this repo publishes."""

import pathlib
import sys

action_path, image_path = sys.argv[1:]
image = pathlib.Path(image_path).read_text().strip()
action = pathlib.Path(action_path)
text = action.read_text()
old = """        else
          echo "Using a forked version"
          METRICS_IMAGE=metrics:forked-$METRICS_VERSION
        fi
"""
new = f"""        else
          echo "Using the image published from this repository"
          METRICS_IMAGE={image}
          echo "Pulling $METRICS_IMAGE"
          if ! docker image pull "$METRICS_IMAGE"; then
            echo "::error::Could not pull $METRICS_IMAGE. Run the Publish metrics image workflow first."
            exit 1
          fi
        fi
"""
if old not in text:
    raise SystemExit("action.yml does not contain the expected fork image block")
action.write_text(text.replace(old, new, 1))
print(f"patched {action} to pull {image}")
