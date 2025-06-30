
seal:
    #!/bin/bash
    set -euo pipefail
    shopt -s nullglob extglob

    UNSEALED_TARGETS="./targets"
    SEALED_TARGETS="../sealed-credstore/targets"

    mkdir -p "$SEALED_TARGETS"

    for unsealed in "$UNSEALED_TARGETS"/*; do
        [[ -d "$unsealed" ]] || continue
        target=$(basename "$unsealed")
        echo "Processing $target..."
        sealed="$SEALED_TARGETS/$target"
        mkdir -p "$sealed"
        touch "$sealed/.gitkeep"

        # Track which files we process to identify orphaned .age files
        declare -A processed_files

        # Process all unsealed files
        [[ -r "$unsealed/.age-recipients" ]] && for src in "$unsealed"/*; do
            [[ -f "$src" ]] || continue
            key=$(basename "$src")
            sealed_file="$sealed/$key.age"
            processed_files["$key.age"]=1

            # Create or update if source is newer or sealed doesn't exist
            if [[ ! -f "$sealed_file" ]] || [[ "$src" -nt "$sealed_file" ]]; then
                echo "  Sealing $key..."
                age -e -a -R "$unsealed/.age-recipients" "$src" >"$sealed_file"
            fi
        done

        # Remove orphaned .age files (where source no longer exists)
        for sealed_file in "$sealed"/*.age; do
            [[ -f "$sealed_file" ]] || continue
            filename=$(basename "$sealed_file")
            if [[ -z "${processed_files[$filename]:-}" ]]; then
                echo "  Removing orphaned $filename..."
                rm "$sealed_file"
            fi
        done

        unset processed_files
    done


lookup-records:
    #!/usr/bin/env nu
    cd targets
    ls
    | each {|tgt|
        http get -H {Authorization: $"Bearer ($env.LINODE_API_TOKEN)"} $"https://api.linode.com/v4/domains/($env.LINODE_DOMAIN_ID)/records"
        | get data
        | where $it.name == $tgt.name and ($it.type == "A" or $it.type == "AAAA")
      }
    | flatten
    | upsert file {|r| $"($r.name)/linode-dns-updater.($r.type | str downcase)_record_id" }
    | where not ($it.file | path exists)
    | each {|r| $r.id | save $r.file; $r }
