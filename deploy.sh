#!/bin/bash

# Copy a script in the output directory to a series of folders in a target directory
# In ComputerCraft, each computer has a numbered folder, e.g. 1, 2, 3 etc.
# You can create the folders before the computer has been initialized,
# and the scripts will be available when the computer is created.

# Each computer should get the chosen script from the output directory,
# as well as a "startup" shell script that runs the script when the computer starts.

# Usage: ./deploy.sh <script_name> <start> <end> <target_directory>

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <script_name> <start> <end> ? <target_directory>"
    echo "script_name: Name of the script to deploy, use compile.sh to generate it."
    echo "start/end: Number of ComputerCraft computers to deploy to, e.g. 1 10."
    echo "target_directory: Directory of the 'computer' folder in the minecraft save."
    echo "target_directory will be cached in the output dir, so you can omit it from later runs."
    exit 1
fi

script_name="$1"
start="$2"
end="$3"
target_directory="$4"

output_file="output/$script_name"
if [ ! -f "$output_file" ]; then
    echo "Error: Output file '$output_file' does not exist."
    exit 1
fi

# validate start and end
if ! [[ "$start" =~ ^[0-9]+$ ]] || ! [[ "$end" =~ ^[0-9]+$ ]]; then
    echo "Error: Start and end must be positive integers."
    exit 1
fi

# helper function to make a shortForm of the target directory
shortForm() {
    local dir="$1"
    # End of the directory will usually look like 'saves\My World 2\computer'
    # We want to return whatever is in the last 2 folders, e.g. 'My World 2\computer'
    local last_two=$(echo "$dir" | awk -F'/' '{print $(NF-1)"/"$NF}' | sed 's/\\/\//g')
    echo "$last_two"
}

# validate target directory
if [ -z "$target_directory" ]; then
    # if no target directory is provided, use the cached one
    if [ -f "output/target_directory.txt" ]; then
        target_directory=$(cat output/target_directory.txt)
        echo "Using cached target directory"
    else
        echo "Error: No target directory provided and no cached target directory found."
        exit 1
    fi
else
    # modify target directory to WSL compatible path if necessary
    if [[ "$target_directory" == C:* ]]; then
        echo "Detected Windows path, attempting to convert to WSL format."
        # Dude nice there's a 'wslpath' command that just does this
        target_directory=$(wslpath -u "$target_directory")
        if [ $? -ne 0 ]; then
            echo "Error: Failed to convert target directory to WSL format."
            exit 1
        fi
        echo "Converted target directory WSL format: '$(shortForm "$target_directory")'"
    fi

    # save the target directory for future runs
    mkdir -p output
    echo "$target_directory" > output/target_directory.txt
    echo "Target directory cached"
fi

mkdir -p "$target_directory"

echo "Deploying script '$script_name' to computers $start to $end in: '$(shortForm "$target_directory")'"
for ((i = start; i <= end; i++)); do
    computer_dir="$target_directory/$i"
    mkdir -p "$computer_dir"

    # Copy the script to the computer directory
    cp "$output_file" "$computer_dir/"

    # Create a startup script that runs the copied script
    echo "print('Startup script running $script_name')" > "$computer_dir/startup"
    echo "shell.run('$script_name')" >> "$computer_dir/startup"
done

echo "Deployment complete."
