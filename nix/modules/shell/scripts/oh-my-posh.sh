#!/usr/bin/env bash

#provide path to oh-my-posh installed themes

# Get a list of all JSON theme files in the directory
omp_themes=($(ls "$omp_themes_dir"/*.json))

# Get the number of JSON theme files
num_files=${#omp_themes[@]}

# Generate a random index
random_index=$((RANDOM % num_files))

# Select a random theme
random_omp_theme=${omp_themes[$random_index]}

eval "$(oh-my-posh init "$SHELL" --config "$random_omp_theme")" || true
