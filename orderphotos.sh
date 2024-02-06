#!/bin/bash

dir=$1
period=$2

# Check of path een geldige directory is.
if [ ! -d "$dir" ]; then
    echo "Could not find: $dir"
    exit 1
fi

# Check of input geldig is.
if [ "$period" != "week" ] && [ "$period" != "month" ]; then
    echo "Unknown option: $2, choose week or month"
    exit 1
fi

# Sorteer op basis van aantal ms.
if [ "$period" == "week" ]; then
    photo_limit=604800
elif [ "$period" == "month" ]; then
    photo_limit=2592000
fi

time_now=$(date +%s)

# Filter op bestandsextenties.
find "$dir" -type f \( \
            -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
         -o -iname "*.gif" -o -iname "*.tiff" -o -iname "*.tif" \
         -o -iname "*.bmp" -o -iname "*.webp" -o -iname "*.svg" \
         -o -iname "*.psd" -o -iname "*.heic" -o -iname "*.heif"\
    \) -print0 |

# Loop door directory heen en verplaats de foto naar de juste subdirectory.
while IFS= read -r -d $'\0' photo; do
    mod_date=$(date -r "$photo" +%s)
    photo_age=$((time_now - mod_date))

    # Als de foto niet ouder is dan een maand of een week, laat hem dan staan.
    if [ "$photo_age" -lt "$photo_limit" ]; then
        continue
    fi

    # Selecteer de subdirectory op basis van periode en modified datum.
    if [ "$period" == "week" ]; then
        week_nr=$(date -r "$photo" +%U)
        dest="$dir/week_$week_nr"
    elif [ "$period" == "month" ]; then
        month=$(date -r "$photo" +%B)
        dest="$dir/$month"
    fi

    # Als de subdirectory niet bestaat wordt deze aangemaakt.
    if [ ! -d "$dest" ]; then
        mkdir "$dest"
    fi

    # Kopieer foto naar de subdirectory op basis van periode en modified datum.
    cp "$photo" "$dest"
    copy="$dest/$(basename "$photo")"

    # Check MD5 hash, als deze klopt verwijder het origineel.
    if [ $(md5sum "$photo" | awk '{print $1}') == $(md5sum "$copy" | awk '{print $1}') ]; then
        rm "$photo"
    else
        echo "Copying $photo unsuccesfull"
    fi
done