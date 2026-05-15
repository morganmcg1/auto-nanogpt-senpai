import os
import sys
from pathlib import Path

from huggingface_hub import hf_hub_download

# Download the GPT-2 tokens of Fineweb10B from huggingface. This
# saves about an hour of startup time compared to regenerating them.
def local_dir():
    repo_data_dir = Path(__file__).resolve().parent / "fineweb10B"
    shared_dir = os.environ.get("FINEWEB10B_DIR")
    pvc_mount = os.environ.get("PVC_MOUNT_PATH")
    if shared_dir is None and pvc_mount and Path(pvc_mount).exists():
        shared_dir = str(Path(pvc_mount) / "datasets" / "fineweb10B")
    if shared_dir is None:
        repo_data_dir.mkdir(parents=True, exist_ok=True)
        return repo_data_dir

    target_dir = Path(shared_dir).expanduser().resolve()
    target_dir.mkdir(parents=True, exist_ok=True)
    if repo_data_dir.exists():
        try:
            if repo_data_dir.resolve() == target_dir:
                return target_dir
        except FileNotFoundError:
            pass
        if repo_data_dir.is_symlink():
            repo_data_dir.unlink()
        elif any(repo_data_dir.iterdir()):
            print(f"Using existing local data directory {repo_data_dir}; set FINEWEB10B_DIR before populating to use shared cache.")
            return repo_data_dir
        else:
            repo_data_dir.rmdir()
    try:
        repo_data_dir.symlink_to(target_dir, target_is_directory=True)
    except FileExistsError:
        pass
    return target_dir


LOCAL_DIR = local_dir()


def get(fname):
    if not (LOCAL_DIR / fname).exists():
        hf_hub_download(repo_id="kjj0/fineweb10B-gpt2", filename=fname,
                        repo_type="dataset", local_dir=LOCAL_DIR)


get("fineweb_val_%06d.bin" % 0)
num_chunks = 103 # full fineweb10B. Each chunk is 100M tokens
if len(sys.argv) >= 2: # we can pass an argument to download less
    num_chunks = int(sys.argv[1])
for i in range(1, num_chunks+1):
    get("fineweb_train_%06d.bin" % i)
