#!/bin/bash

# Default mode
mode="default"

# Default output file
output_file="savefile.json"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--random)
            mode="random"
            shift
            ;;
        -d|--default)
            mode="default"
            shift
            ;;
        -f|--files)
            shift
            # Collect all following arguments until we hit another option
            input_files=()
            while [[ $# -gt 0 ]] && ! [[ $1 =~ ^- ]]; do
                input_files+=("$1")
                shift
            done
            ;;
        -o|--output)
            output_file="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# File paths
if [ ${#input_files[@]} -eq 0 ]; then
    input_files=("books.md")
fi

# Initialize counters
fastId=1
category_num=1
book_in_category=1
total_books=0

# Function to count total books
count_books() {
    local count=0
    for input_file in "${input_files[@]}"; do
        while IFS= read -r line; do
            if [[ "$line" =~ ^- ]]; then
                ((count++))
            fi
        done < "$input_file"
    done
    echo "$count"
}

# Function to generate book ID
generate_book_id() {
    printf "0.%d00000000000000%d" "$category_num" "$book_in_category"
}

# Function to format JSON entry
format_json_entry() {
    local id="$1"
    local name="$2"
    local is_last="$3"
    if [ "$is_last" = true ]; then
        printf '    {"fastId":%d,"id":"%s","extra":null,"amount":null,"name":"%s","investors":[]}' \
            "$fastId" "$id" "$name"
    else
        printf '    {"fastId":%d,"id":"%s","extra":null,"amount":null,"name":"%s","investors":[]},' \
            "$fastId" "$id" "$name"
    fi
}

# Function to process input and generate JSON
generate_json() {
    local is_first=true
    for input_file in "${input_files[@]}"; do
        while IFS= read -r line; do
            if [[ "$line" =~ ^- ]]; then
                # Extract book name
                book_name=$(echo "$line" | sed 's/^- //' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

                # Generate book ID
                book_id=$(generate_book_id)

                # Format JSON entry
                if [ "$is_first" = true ]; then
                    is_last=false
                    if [ "$fastId" -eq "$total_books" ]; then
                        is_last=true
                    fi
                    json_entry=$(format_json_entry "$book_id" "$book_name" "$is_last")
                    echo "$json_entry" >> "$output_file"
                    is_first=false
                else
                    is_last=false
                    if [ "$fastId" -eq "$total_books" ]; then
                        is_last=true
                    fi
                    json_entry=$(format_json_entry "$book_id" "$book_name" "$is_last")
                    echo "$json_entry" >> "$output_file"
                fi

                # Update counters
                ((fastId++))
                ((book_in_category++))

                if [ "$book_in_category" -gt 3 ]; then
                    book_in_category=1
                    ((category_num++))
                fi
            fi
        done < "$input_file"
    done
}

# Main logic
total_books=$(count_books)
> "$output_file"
echo "[" >> "$output_file"

if [ "$mode" = "random" ]; then
    # Create temporary file to store all JSON entries
    temp_file=$(mktemp)

    # Collect all book entries into the temporary file
    fastId=1
    category_num=1
    book_in_category=1
    for input_file in "${input_files[@]}"; do
        while IFS= read -r line; do
            if [[ "$line" =~ ^- ]]; then
                book_name=$(echo "$line" | sed 's/^- //' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                book_id=$(generate_book_id)

                json_entry=$(printf '    {"fastId":%d,"id":"%s","extra":null,"amount":null,"name":"%s","investors":[]}' \
                            "$fastId" "$book_id" "$book_name")
                echo "$json_entry" >> "$temp_file"
                ((fastId++))
                ((book_in_category++))

                if [ "$book_in_category" -gt 3 ]; then
                    book_in_category=1
                    ((category_num++))
                fi
            fi
        done < "$input_file"
    done

    # Shuffle the entries and write to output file
    shuffled_entries=$(shuf "$temp_file")
    
    # Count total entries for proper comma placement
    entry_count=$(wc -l < "$temp_file")
    current_entry=1
    
    while IFS= read -r line; do
        if [ "$current_entry" -eq "$entry_count" ]; then
            # Last entry - no comma
            echo "$line" >> "$output_file"
        else
            # Add comma to all entries except the last one
            echo "$line," >> "$output_file"
        fi
        ((current_entry++))
    done <<< "$shuffled_entries"

    # Remove the temporary file
    rm "$temp_file"
else
    generate_json
fi

# Close the JSON array
echo -e "]" >> "$output_file"

# Print completion message
echo "Преобразование завершено. Результат сохранен в $output_file"
