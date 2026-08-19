import ast
import os
import struct
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch


TRACK_DIR = Path(__file__).parents[1] / "records" / "track_3_optimization"
sys.path.insert(0, str(TRACK_DIR))

from eval_runtime import (
    EXPECTED_TRAIN_SHARDS,
    EXPECTED_VAL_SHARDS,
    FINEWEB_MAGIC,
    FINEWEB_SHARD_BYTES,
    FINEWEB_SHARD_TOKENS,
    FINEWEB_VERSION,
    apply_torch_seed,
    arm_hard_timeout,
    has_exact_fineweb_shards,
    resolve_trial_seed,
    resolve_wandb_group,
    summarize_trials,
    timeout_minutes_from_env,
)


class EvalRuntimeTest(unittest.TestCase):
    def test_training_script_records_the_effective_group_and_eval_contract(self):
        tree = ast.parse((TRACK_DIR / "train_gpt_simple.py").read_text())
        call = next(
            node
            for node in ast.walk(tree)
            if isinstance(node, ast.Call)
            and isinstance(node.func, ast.Attribute)
            and isinstance(node.func.value, ast.Name)
            and node.func.value.id == "wandb"
            and node.func.attr == "init"
        )
        keywords = {keyword.arg: keyword.value for keyword in call.keywords}
        self.assertEqual(ast.unparse(keywords["group"]), "wandb_group")
        config_keys = {
            key.value
            for key in keywords["config"].keys
            if isinstance(key, ast.Constant) and isinstance(key.value, str)
        }
        self.assertGreaterEqual(
            config_keys,
            {
                "wandb_run_group",
                "senpai_timeout_minutes",
                "senpai_trial_index",
                "senpai_trial_seed",
                "source_sha256",
                "train_shards",
                "val_shards",
                "data_contract",
                "metric_contract",
            },
        )

    def test_wandb_group_env_overrides_cli(self):
        with patch.dict(os.environ, {"WANDB_RUN_GROUP": "eval-group"}):
            self.assertEqual(resolve_wandb_group("cli-group"), "eval-group")

    def test_wandb_group_uses_cli_outside_harness(self):
        with patch.dict(os.environ, {}, clear=True):
            self.assertEqual(resolve_wandb_group("local-group"), "local-group")

    def test_trial_seed_env_overrides_cli_and_local_seed_still_works(self):
        with patch.dict(os.environ, {"SENPAI_TRIAL_SEED": "29"}):
            self.assertEqual(resolve_trial_seed(7), 29)
        with patch.dict(os.environ, {}, clear=True):
            self.assertEqual(resolve_trial_seed(7), 7)

    def test_authoritative_seed_is_applied_to_cpu_and_cuda(self):
        torch_module = Mock()

        apply_torch_seed(torch_module, 29)

        torch_module.manual_seed.assert_called_once_with(29)
        torch_module.cuda.manual_seed_all.assert_called_once_with(29)

    def test_fineweb_manifest_matches_exact_names_not_only_counts(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            paths = []
            for name in (*EXPECTED_TRAIN_SHARDS, *EXPECTED_VAL_SHARDS):
                path = root / name
                with path.open("wb") as shard:
                    shard.write(
                        struct.pack(
                            "<iii",
                            FINEWEB_MAGIC,
                            FINEWEB_VERSION,
                            FINEWEB_SHARD_TOKENS,
                        )
                    )
                    shard.truncate(FINEWEB_SHARD_BYTES)
                paths.append(path)
            train, validation = paths[:-1], paths[-1:]

            self.assertTrue(has_exact_fineweb_shards(train, validation))
            self.assertFalse(has_exact_fineweb_shards(train[:-1], validation))

            with train[-1].open("r+b") as shard:
                shard.write(struct.pack("<i", 0))
            self.assertFalse(has_exact_fineweb_shards(train, validation))

    def test_ranking_requires_every_target_crossing_and_statistical_gate(self):
        passing = [
            {
                "final_val_loss": loss,
                "first_step_to_target": 3300,
            }
            for loss in (3.2770, 3.2772, 3.2774, 3.2776)
        ]
        summary = summarize_trials(passing, 4, 3.28, 0.004)
        self.assertTrue(summary["all_reached_target"])
        self.assertTrue(summary["statistically_valid"])
        self.assertTrue(summary["trial_ranking_eligible"])

        missed_target = [dict(result) for result in passing]
        missed_target[-1]["first_step_to_target"] = -1
        missed_summary = summarize_trials(missed_target, 4, 3.28, 0.004)
        self.assertFalse(missed_summary["all_reached_target"])
        self.assertFalse(missed_summary["trial_ranking_eligible"])

        weak_losses = [
            {"final_val_loss": 3.2795, "first_step_to_target": 3300}
            for _ in range(4)
        ]
        weak_summary = summarize_trials(weak_losses, 4, 3.28, 0.004)
        self.assertFalse(weak_summary["statistically_valid"])
        self.assertFalse(weak_summary["trial_ranking_eligible"])

    def test_timeout_requires_a_positive_finite_value(self):
        for value in ("0", "-1", "nan", "inf"):
            with self.subTest(value=value), patch.dict(
                os.environ, {"SENPAI_TIMEOUT_MINUTES": value}
            ):
                with self.assertRaises(ValueError):
                    timeout_minutes_from_env()

    @patch("eval_runtime.threading.Timer")
    def test_hard_timeout_starts_daemon_timer(self, timer_class):
        timer = timer_class.return_value

        self.assertIs(arm_hard_timeout(1.5), timer)
        timer_class.assert_called_once()
        self.assertEqual(timer_class.call_args.args[0], 90.0)
        self.assertTrue(timer.daemon)
        timer.start.assert_called_once_with()

        terminate = timer_class.call_args.args[1]
        with patch("eval_runtime.os.write"), patch("eval_runtime.os._exit") as hard_exit:
            terminate()
        hard_exit.assert_called_once_with(124)

    def test_watchdog_actually_terminates_a_process(self):
        env = {**os.environ, "SENPAI_TIMEOUT_MINUTES": "0.001"}
        result = subprocess.run(
            [
                sys.executable,
                "-c",
                "from eval_runtime import arm_hard_timeout, timeout_minutes_from_env; "
                "import time; arm_hard_timeout(timeout_minutes_from_env()); time.sleep(2)",
            ],
            cwd=TRACK_DIR,
            env=env,
            capture_output=True,
            text=True,
            timeout=3,
        )
        self.assertEqual(result.returncode, 124)
        self.assertIn("expired; terminating process", result.stderr)


if __name__ == "__main__":
    unittest.main()
