#!/bin/bash

# Private AI Setup Dream Guide - AI Video Generation Model Setup
# Written by Ugo Emekauwa (uemekauw@cisco.com, uemekauwa@gmail.com)
# GitHub Repository: https://github.com/ugo-emekauwa/making-commercials-with-ltx-ai-video-guide
# Summary: This script sets up an environment with the AI video generation model LTX-2 from Lightricks, in full (FP8) and distilled formats.
## ComfyUI serves as a frontend user-friendly GUI interface for interacting with the AI video and image generation models.

# Setup the Script Variables
echo "Setting up the Script Variables..."
set -o nounset
target_host=127.0.0.1
comfyui_container_image="ghcr.io/lecode-official/comfyui-docker@sha256:e27739fc19d577d694ea99846a6c602e06dac963bebb2f056e22d97d19c392dd"
comfyui_container_host_port=8188
stop_and_remove_preexisting_private_ai_containers=true

# Start the AI Video Generation Model Setup
echo "Starting the AI Video Generation Model Setup..."

# Create the 'comfyui' Folder and Sub-Folders in the $HOME Directory
echo "Creating the 'comfyui' Folder and Sub-Folders in the $HOME Directory..."
mkdir -p $HOME/ai_models/comfyui/models
mkdir -p $HOME/ai_models/comfyui/custom_nodes
mkdir -p $HOME/ai_models/comfyui/input
mkdir -p $HOME/ai_models/comfyui/output
mkdir -p $HOME/ai_models/comfyui/workflows

# Update the Permissions of the 'comfyui' Folder
echo "Updating the Permissions of the 'comfyui' Folder..."
sudo chown -R $(whoami) $HOME/ai_models/comfyui
sudo chmod -R a+w $HOME/ai_models/comfyui

# Clear the Hugging Face Cache of Any Previously Downloaded AI Models and Files
echo "Clearing the Hugging Face Cache of Any Previously Downloaded AI Models and Files..."
for directory in $HOME/ai_models/*/.cache/huggingface/download/ $HOME/ai_models/comfyui/models/*/.cache/huggingface/download/; do
	sudo rm -rf "$directory"/* 2>/dev/null
done

# Download the AI Video Generation Models
echo "Downloading the AI Video Generation Models..."
HF_HUB_ENABLE_HF_TRANSFER=1 hf download Lightricks/LTX-2 ltx-2-19b-dev-fp8.safetensors --local-dir $HOME/ai_models/comfyui/models/checkpoints
HF_HUB_ENABLE_HF_TRANSFER=1 hf download Lightricks/LTX-2 ltx-2-19b-distilled.safetensors --local-dir $HOME/ai_models/comfyui/models/checkpoints
HF_HUB_ENABLE_HF_TRANSFER=1 hf download Lightricks/LTX-2 ltx-2-spatial-upscaler-x2-1.0.safetensors --local-dir $HOME/ai_models/comfyui/models/latent_upscale_models
HF_HUB_ENABLE_HF_TRANSFER=1 hf download Lightricks/LTX-2-19b-LoRA-Camera-Control-Dolly-Left ltx-2-19b-lora-camera-control-dolly-left.safetensors --local-dir $HOME/ai_models/comfyui/models/loras
HF_HUB_ENABLE_HF_TRANSFER=1 hf download Lightricks/LTX-2 ltx-2-19b-distilled-lora-384.safetensors --local-dir $HOME/ai_models/comfyui/models/loras
HF_HUB_ENABLE_HF_TRANSFER=1 hf download Comfy-Org/ltx-2 split_files/text_encoders/gemma_3_12B_it.safetensors --local-dir $HOME/ai_models/comfyui/models/text_encoders
mv $HOME/ai_models/comfyui/models/text_encoders/split_files/text_encoders/gemma_3_12B_it.safetensors $HOME/ai_models/comfyui/models/text_encoders/
rm -rf $HOME/ai_models/comfyui/models/text_encoders/split_files/

# Stop and Remove Preexisting Private AI Containers
private_ai_containers=("open-webui-1" "vllm-chat-model-1" "vllm-chat-model-2" "sglang-vision-model-1" "vllm-reasoning-model-1" "sd-webui-forge-1" "vllm-vision-model-1" "comfyui-1")
if [ "$stop_and_remove_preexisting_private_ai_containers" = "true" ]; then
    echo "Stopping Preexisting Private AI Containers..."
    if docker info -f "{{println .SecurityOptions}}" 2>/dev/null | grep -q rootless; then
        docker stop "${private_ai_containers[@]}" 2>/dev/null
    else
        sudo docker stop "${private_ai_containers[@]}" 2>/dev/null
    fi

    echo "Removing Preexisting Private AI Containers..."
    if docker info -f "{{println .SecurityOptions}}" 2>/dev/null | grep -q rootless; then
        docker rm "${private_ai_containers[@]}" 2>/dev/null
    else
        sudo docker rm "${private_ai_containers[@]}" 2>/dev/null
    fi
fi

# Pause for clearing of the GPU vRAM
echo "Waiting for Clearing of the GPU vRAM, if Needed..."
sleep 5

# Setup the Container with ComfyUI
echo "Setting up the Container with ComfyUI..."
comfyui_container_args_base=(
    -d
    --restart unless-stopped
    --name comfyui-1
    -p $comfyui_container_host_port:8188
    -v $HOME/ai_models/comfyui/models/:/opt/comfyui/models:rw
    -v $HOME/ai_models/comfyui/custom_nodes/:/opt/comfyui/custom_nodes:rw
    -v $HOME/ai_models/comfyui/input/:/opt/comfyui/input:rw
    -v $HOME/ai_models/comfyui/output/:/opt/comfyui/output:rw
    -v $HOME/ai_models/comfyui/workflows/:/opt/comfyui/user/default/workflows:rw
    --gpus all
    --runtime nvidia
    $comfyui_container_image
)
if docker info -f "{{println .SecurityOptions}}" 2>/dev/null | grep -q rootless; then
    docker run "${comfyui_container_args_base[@]}"
else
    sudo docker run "${comfyui_container_args_base[@]}"
fi

if [[ $? -eq 0 ]]; then
    sleep 5
    echo "The Container with ComfyUI has Started..."
else
    echo "ERROR: The Container with ComfyUI Failed to Start!"
    exit 1
fi

# Update the Permissions of the 'comfyui' Folder
echo "Updating the Permissions of the 'comfyui' Folder..."
sudo chmod -R a+w $HOME/ai_models/comfyui

# Pause for the ComfyUI to Fully Come Online
echo "Waiting for the ComfyUI to Fully Come Online..."
sleep 10
echo "The Private AI Interface Will Be Available At http://$target_host:$comfyui_container_host_port"

# End the AI Video Model Setup
echo "The AI Video Generation Model Setup has Completed."
