#!/bin/bash
# H223 sequential 3-arm chain on 1xGPU. Aux AdamW eps ablation.
# arm_a CTRL eps=1e-6 (H203 baseline reproduce, bit-identical)
# arm_b EPS_1E8 eps=1e-8 (PyTorch default)
# arm_c EPS_1E4 eps=1e-4 (larger denominator floor)
set -e
cd /workspace/senpai/target

mkdir -p logs

ts() { date +"%Y-%m-%dT%H:%M:%SZ"; }

echo "[$(ts)] H223 chain start" | tee -a logs/H223_chain.txt

# arm_a CTRL eps=1e-6 (bit-identical H203 baseline)
echo "[$(ts)] launching arm_a CTRL eps=1e-6" | tee -a logs/H223_chain.txt
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape cosine \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --aux_adamw_eps 1e-6 \
  --muonh_agc_clip_ratio 0.05 --aux_agc_clip_ratio 0.05 \
  --muonh_warmup_steps 100 \
  --body_init orthogonal_fnorm_matched \
  --wandb_group H223 --wandb_name g1r3-nezuko/H223-arm_a-CTRL \
  > logs/H223_arm_a_CTRL.txt 2>&1
echo "[$(ts)] arm_a CTRL exit=$?" | tee -a logs/H223_chain.txt

# arm_b EPS_1E8 eps=1e-8 (PyTorch default)
echo "[$(ts)] launching arm_b EPS_1E8 eps=1e-8" | tee -a logs/H223_chain.txt
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape cosine \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --aux_adamw_eps 1e-8 \
  --muonh_agc_clip_ratio 0.05 --aux_agc_clip_ratio 0.05 \
  --muonh_warmup_steps 100 \
  --body_init orthogonal_fnorm_matched \
  --wandb_group H223 --wandb_name g1r3-nezuko/H223-arm_b-EPS_1E8 \
  > logs/H223_arm_b_EPS_1E8.txt 2>&1
echo "[$(ts)] arm_b EPS_1E8 exit=$?" | tee -a logs/H223_chain.txt

# arm_c EPS_1E4 eps=1e-4 (larger denominator floor)
echo "[$(ts)] launching arm_c EPS_1E4 eps=1e-4" | tee -a logs/H223_chain.txt
torchrun --standalone --nproc_per_node=1 \
  records/track_3_optimization/train_gpt_simple.py \
  --num_trials 1 --train_steps 3325 \
  --muonh_mode scale_invariant \
  --muonh_cooldown_shape cosine \
  --muonh_mu_schedule linear --muonh_mu_start 0.95 --muonh_mu_end 0.90 \
  --aux_beta2_schedule constant --aux_beta2_start 0.99 \
  --aux_adamw_eps 1e-4 \
  --muonh_agc_clip_ratio 0.05 --aux_agc_clip_ratio 0.05 \
  --muonh_warmup_steps 100 \
  --body_init orthogonal_fnorm_matched \
  --wandb_group H223 --wandb_name g1r3-nezuko/H223-arm_c-EPS_1E4 \
  > logs/H223_arm_c_EPS_1E4.txt 2>&1
echo "[$(ts)] arm_c EPS_1E4 exit=$?" | tee -a logs/H223_chain.txt

echo "[$(ts)] H223 chain complete" | tee -a logs/H223_chain.txt
