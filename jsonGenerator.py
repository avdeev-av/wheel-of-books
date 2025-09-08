#!/usr/bin/env python3

import argparse
import json
import random
import os
from pathlib import Path

def parse_arguments():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group()
    group.add_argument('-r', '--random', action='store_true', help='Randomize output order')
    group.add_argument('-d', '--default', action='store_true', default=True, help='Default mode (default)')
    
    parser.add_argument('-f', '--files', nargs='+', default=['books.md'], help='Input files')
    parser.add_argument('-o', '--output', default='savefile.json', help='Output file')
    
    return parser.parse_args()

def count_books(input_files):
    """Count total books from input files."""
    count = 0
    for file_path in input_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                for line in f:
                    if line.strip().startswith('-'):
                        count += 1
        except FileNotFoundError:
            print(f"Warning: File {file_path} not found")
    return count

def generate_book_id(category_num, book_in_category):
    """Generate book ID in format '0.xxxxxxxxxxxxxxxxd'."""
    return f"0.{category_num}00000000000000{book_in_category}"

def process_input_files(input_files):
    """Process input files and generate book entries."""
    books = []
    
    fast_id = 1
    category_num = 1
    book_in_category = 1
    
    for file_path in input_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                for line in f:
                    if line.strip().startswith('-'):
                        # Extract book name
                        book_name = line[2:].strip()
                        
                        # Generate book ID
                        book_id = generate_book_id(category_num, book_in_category)
                        
                        # Create book entry
                        book_entry = {
                            "fastId": fast_id,
                            "id": book_id,
                            "extra": None,
                            "amount": None,
                            "name": book_name,
                            "investors": []
                        }
                        
                        books.append(book_entry)
                        
                        # Update counters
                        fast_id += 1
                        book_in_category += 1
                        
                        if book_in_category > 3:
                            book_in_category = 1
                            category_num += 1
        except FileNotFoundError:
            print(f"Warning: File {file_path} not found")
    
    return books

def main():
    args = parse_arguments()
    
    # Count total books
    total_books = count_books(args.files)
    
    # Process input files to get book entries
    books = process_input_files(args.files)
    
    # Apply randomization if requested
    if args.random:
        random.shuffle(books)
    
    # Write JSON output with proper UTF-8 encoding
    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(books, f, ensure_ascii=False, indent=4)
    
    print(f"Преобразование завершено. Результат сохранен в {args.output}")

if __name__ == "__main__":
    main()
    