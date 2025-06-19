#!/bin/bash

input_file="books.md"
output_file="saveFile.json"

> "$output_file"
echo "[" >> "$output_file"

fastId=1
category_num=1
book_in_category=1

while IFS= read -r line; do
    if [[ "$line" =~ ^- ]]; then
        book_name=$(echo "$line" | sed 's/^- //' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        book_id=$(printf "0.%d00000000000000%d" "$category_num" "$book_in_category")
        
        json_entry=$(printf '    {"fastId":%d,"id":"%s","extra":null,"amount":null,"name":"%s","investors":[]}' \
                    "$fastId" "$book_id" "$book_name")
        
        if [ "$fastId" -gt 1 ]; then
            echo "," >> "$output_file"
        fi
        echo "$json_entry" >> "$output_file"
        
        ((fastId++))
        ((book_in_category++))
        
        if [ "$book_in_category" -gt 3 ]; then
            book_in_category=1
            ((category_num++))
        fi
    fi
done < "$input_file"

echo -e "\n]" >> "$output_file"

echo "Преобразование завершено. Результат сохранен в $output_file"