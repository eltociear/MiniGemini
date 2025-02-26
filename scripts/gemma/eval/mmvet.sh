#!/bin/bash

CUDA_VISIBLE_DEVICES='0,1,2,3,4,5,6,7'
gpu_list="${CUDA_VISIBLE_DEVICES:-0}"
IFS=',' read -ra GPULIST <<< "$gpu_list"
CHUNKS=${#GPULIST[@]}

CKPT="Mini-Gemini/Mini-Gemini-2B"

for IDX in $(seq 0 $((CHUNKS-1))); do
  CUDA_VISIBLE_DEVICES=${GPULIST[$IDX]} python -m minigemini.eval.model_vqa \
    --model-path work_dirs/$CKPT \
    --question-file data/MiniGemini-Eval/mm-vet/llava-mm-vet.jsonl \
    --image-folder data/MiniGemini-Eval/mm-vet/images \
    --answers-file data/MiniGemini-Eval/mm-vet/answers/$CKPT/${CHUNKS}_${IDX}.jsonl \
    --num-chunks $CHUNKS \
    --chunk-idx $IDX \
    --temperature 0 \
    --conv-mode gemma &


wait

output_file=data/MiniGemini-Eval/mm-vet/answers/$CKPT/merge.jsonl
# Clear out the output file if it exists.
> "$output_file"

# Loop through the indices and concatenate each file.
for IDX in $(seq 0 $((CHUNKS-1))); do
    cat data/MiniGemini-Eval/mm-vet/answers/$CKPT/${CHUNKS}_${IDX}.jsonl >> "$output_file"
done

mkdir -p data/MiniGemini-Eval/mm-vet/results/$CKPT

python scripts/convert_mmvet_for_eval.py \
    --src $output_file \
    --dst data/MiniGemini-Eval/mm-vet/results/$CKPT/$CKPT.json

