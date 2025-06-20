#!/bin/bash

input_file="books.md"
output_file="savefile_random.json"

> "$output_file"
echo "[" >> "$output_file"

fastId=1
category_num=1
book_in_category=1
total_books=0

# Создаем временный файл для хранения всех JSON записей
temp_file=$(mktemp)

# Сначала подсчитываем общее количество книг
while IFS= read -r line; do
    if [[ "$line" =~ ^- ]]; then
        ((total_books++))
    fi
done < "$input_file"

# Собираем все записи во временный файл
while IFS= read -r line; do
    if [[ "$line" =~ ^- ]]; then
        book_name=$(echo "$line" | sed 's/^- //' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Формируем ID
        book_id=$(printf "0.%d00000000000000%d" "$category_num" "$book_in_category")
        
        # Формируем JSON запись
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

# Перемешиваем записи
shuffled_entries=$(shuf "$temp_file")

# Обновляем fastId в перемешанных записях
fastId=1
while IFS= read -r line; do
    # Обновляем fastId в строке
    updated_line=$(echo "$line" | sed "s/\"fastId\":[0-9]*,/\"fastId\":$fastId,/")
    
    if [ $fastId -eq $total_books ]; then
        echo "$updated_line" >> "$output_file"
    else
        echo "$updated_line," >> "$output_file"
    fi
    
    ((fastId++))
done <<< "$shuffled_entries"

# Удаляем временный файл
rm "$temp_file"

echo "$total_books"
echo -e "]" >> "$output_file"

echo "Преобразование завершено. Результат сохранен в $output_file"
