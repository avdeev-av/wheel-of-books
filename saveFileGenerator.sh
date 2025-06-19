#!/bin/bash

input_file="books.md"
output_file="savefile.json"

> "$output_file"
echo "[" >> "$output_file"

fastId=1
category_num=1
book_in_category=1
total_books=0

while IFS= read -r line; do
    if [[ "$line" =~ ^- ]]; then
        ((total_books++))
    fi
done < "$input_file"

while IFS= read -r line; do
    if [[ "$line" =~ ^- ]]; then
        book_name=$(echo "$line" | sed 's/^- //' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Формируем ID
        book_id=$(printf "0.%d00000000000000%d" "$category_num" "$book_in_category")
        
        # Формируем JSON запись
        if [ $fastId -eq $total_books ]; then
            json_entry=$(printf '    {"fastId":%d,"id":"%s","extra":null,"amount":null,"name":"%s","investors":[]}' \
                        "$fastId" "$book_id" "$book_name")
        else
            json_entry=$(printf '    {"fastId":%d,"id":"%s","extra":null,"amount":null,"name":"%s","investors":[]},' \
                        "$fastId" "$book_id" "$book_name")
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

echo "$total_books"
echo -e "]" >> "$output_file"

echo "Преобразование завершено. Результат сохранен в $output_file"