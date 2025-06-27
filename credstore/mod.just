
seal:
    #!/bin/bash
    set -euo pipefail
    shopt -s nullglob extglob

    UNSEALED_TARGETS="./targets"
    SEALED_TARGETS="../sealed-credstore/targets"

    rm -rf "$SEALED_TARGETS"
    mkdir -p "$SEALED_TARGETS"

    for unsealed in "$UNSEALED_TARGETS"/*; do
        [[ -d "$unsealed" ]] || continue
        target=$(basename "$unsealed")
        echo "Sealing $target..."
        sealed="$SEALED_TARGETS/$target"
        mkdir -p "$sealed"
        touch "$sealed/.gitkeep"
        [[ -r "$unsealed/.age-recipients" ]] || continue
        for src in "$unsealed"/*; do
            key=$(basename "$src")
            age -e -a -R "$unsealed/.age-recipients" "$src" >"$sealed/$key.age"
        done
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
    | upsert file {|r| $"($r.name)/linode-dns-updater.($r.type | str downcase)_record_id"}
    | where not ($it.file | path exists)
    | each {|r| $r.id | save $r.file; $r}
