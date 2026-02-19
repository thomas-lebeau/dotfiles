#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model_name=$(echo "$input" | jq -r '.model.display_name // empty')
agent_name=$(echo "$input" | jq -r '.agent.name // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
api_duration_ms=$(echo "$input" | jq -r '.cost.total_api_duration_ms // 0')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# LINE 1: Git information
# Get git worktree root basename or fallback to current directory relative to home
git_info=""
pr_info=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    # Get git worktree root and extract basename
    worktree_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
    common_git_dir=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    repo_name=$(basename "$(dirname "$common_git_dir")")
    if [ -d "$worktree_root/.git" ]; then
        short_dir="${repo_name} [main]"
    else
        worktree_name=$(basename "$worktree_root")
        worktree_name="${worktree_name#"${repo_name}"}"
        worktree_name="${worktree_name#[-_]}"
        short_dir="${repo_name} [${worktree_name}]"
    fi

    branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
    [ -z "$branch" ] && branch="detached"

    # Replace git username prefix with ~ (e.g., thomas.lebeau/feature -> ~/feature)
    username="$USER"
    if [ -n "$username" ] && [ "$branch" != "detached" ]; then
        branch=$(echo "$branch" | sed "s|^${username}/|~/|")
    fi

    # Check if there are any changes (modified, untracked, or staged files)
    if ! git -C "$cwd" --no-optional-locks diff --quiet 2>/dev/null || \
       ! git -C "$cwd" --no-optional-locks diff --cached --quiet 2>/dev/null || \
       [ -n "$(git -C "$cwd" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null)" ]; then
        dirty="*"
    else
        dirty=""
    fi

    # Check commits ahead/behind remote tracking branch
    ahead_behind=""
    if git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref @{upstream} > /dev/null 2>&1; then
        counts=$(git -C "$cwd" --no-optional-locks rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$counts" ]; then
            ahead=$(echo "$counts" | awk '{print $1}')
            behind=$(echo "$counts" | awk '{print $2}')

            [ "$ahead" -gt 0 ] && ahead_behind="${ahead_behind}↑${ahead}"
            [ "$behind" -gt 0 ] && ahead_behind="${ahead_behind}↓${behind}"
        fi
    fi

    git_info=" | ${branch}${dirty}${ahead_behind}"

    # Get PR info with caching (only if branch is not detached/main/master)
    if [ "$branch" != "detached" ] && [ "$branch" != "main" ] && [ "$branch" != "master" ]; then
        cache_dir="$HOME/.cache/claude-statusline"
        safe_branch="${branch//\//_}"
        cache_file="$cache_dir/pr-${worktree_root//\//_}-${safe_branch}"
        cache_max_age=5  # 5 seconds

        mkdir -p "$cache_dir" 2>/dev/null

        # Check if cache exists and is fresh
        if [ -f "$cache_file" ] && [ $(($(date +%s) - $(date -r "$cache_file" +%s 2>/dev/null || echo 0))) -lt $cache_max_age ]; then
            # Use cached PR info
            pr_data=$(cat "$cache_file" 2>/dev/null)
        elif [ -f "$cache_file" ]; then
            # Stale cache: use it and refresh in background
            pr_data=$(cat "$cache_file" 2>/dev/null)
            (
                pr_result=$(cd "$worktree_root" && gh pr view --json number,url,baseRefName 2>/dev/null)
                if [ $? -eq 0 ] && [ -n "$pr_result" ]; then
                    echo "$pr_result" > "$cache_file"
                else
                    rm -f "$cache_file" 2>/dev/null
                fi
            ) &
        else
            # No cache: fetch synchronously (first run)
            pr_data=$(cd "$worktree_root" && gh pr view --json number,url,baseRefName 2>/dev/null)
            if [ -n "$pr_data" ]; then
                echo "$pr_data" > "$cache_file"
            fi
        fi

        # Parse PR info if we have it
        if [ -n "$pr_data" ]; then
            pr_number=$(echo "$pr_data" | jq -r '.number // empty' 2>/dev/null)
            pr_url=$(echo "$pr_data" | jq -r '.url // empty' 2>/dev/null)
            base_ref=$(echo "$pr_data" | jq -r '.baseRefName // empty' 2>/dev/null)

            if [ -n "$pr_number" ] && [ "$pr_number" != "null" ] && [ -n "$pr_url" ]; then
                # Add base branch if available
                base_info=""
                if [ -n "$base_ref" ] && [ "$base_ref" != "null" ] && [ "$base_ref" != "main" ] && [ "$base_ref" != "master" ]; then
                    # Replace git username prefix with ~ in base branch too
                    display_base=$(echo "$base_ref" | sed "s|^${username}/|~/|")
                    base_info=" → ${display_base}"
                fi
                pr_info="${base_info}"
                # OSC 8 hyperlink: \e]8;;URL\e\\TEXT\e]8;;\e\\
                # pr_info=$(printf "%s | \e]8;;%s\e\\#%s\e]8;;\e\\" "$base_info" "$pr_url" "$pr_number")
            fi
        fi
    fi
else
    # Not in a git repo, fallback to directory path relative to home
    home_dir="${HOME:-$(eval echo ~)}"
    short_dir=$(echo "$cwd" | sed "s|^$home_dir|~|")
fi

line1="${short_dir}${git_info}${pr_info}"

# LINE 2: Claude information (model, agent, context)
line2="${model_name}"

# Format duration helper: ms -> human readable
format_duration() {
    local ms=$1
    local total_secs=$((ms / 1000))
    local h=$((total_secs / 3600))
    local m=$(( (total_secs % 3600) / 60 ))
    local s=$((total_secs % 60))
    if [ "$h" -gt 0 ]; then
        echo "${h}h${m}m"
    elif [ "$m" -gt 0 ]; then
        echo "${m}m${s}s"
    else
        echo "${s}s"
    fi
}

api_time=$(format_duration "$api_duration_ms")
total_time=$(format_duration "$duration_ms")
line2="${line2} | ${api_time} - ${total_time}"

# Add cost
cost_display=$(printf '$%.2f' "$cost")
line2="${line2} | ${cost_display}"

# Add agent name if present
if [ -n "$agent_name" ] && [ "$agent_name" != "null" ]; then
    line2="${line2} | ${agent_name}"
fi

# Build progress bar
# Convert percentage to integer
pct=${used_pct%.*}

# Calculate filled and empty blocks (out of 16 total)
filled=$((pct * 16 / 100))
empty=$((16 - filled))

# Build the bar
bar=""
for ((i=0; i<filled; i++)); do bar="${bar}▓"; done
for ((i=0; i<empty; i++)); do bar="${bar}░"; done

line2="${line2} | ${bar} ${pct}%"


# Output lines
echo "${line1}"
echo "${line2}"
