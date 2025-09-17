#!/usr/bin/env python3

import re
from collections import OrderedDict
from rich.console import Console
from rich.text import Text

def parse_markdown_table(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Find the table start and end
    table_start = None
    table_end = None
    
    for i, line in enumerate(lines):
        if line.strip().startswith('|'):
            if table_start is None:
                table_start = i
            else:
                if not line.strip() or line.strip() == '|':
                    table_end = i
                    break
        elif table_end is not None:
            break
    
    if table_start is None:
        return []
    
    # Extract table rows
    table_rows = [line.strip() for line in lines[table_start:] if line.strip()]
    
    # Skip header row and split into columns
    headers = [h.strip() for h in table_rows[0].split('|')[1:-1]]
    data = []
    
    for row in table_rows[1:]:
        if not row.strip():
            continue
        cells = [c.strip() for c in row.split('|')[1:-1]]
        if len(cells) >= 5:
            # Create dictionary for each row
            entry = {}
            for i, header in enumerate(headers):
                if i < len(cells):
                    entry[header] = cells[i]
            data.append(entry)
    
    return data

def filter_and_sort_entries(entries):
    valid_ratings = {'WW', 'W', 'L', 'LL'}
    filtered_entries = [e for e in entries if e.get('Оценка') in valid_ratings]
    
    # Create ordered dictionary with tiers
    tier_list = OrderedDict()
    tier_list['WW'] = []
    tier_list['W'] = []
    tier_list['L'] = []
    tier_list['LL'] = []
    
    for entry in filtered_entries:
        rating = entry.get('Оценка', '')
        name = entry.get('название', '')
        if rating in tier_list:
            tier_list[rating].append(name)
    
    return tier_list

def generate_tui_tierlist(tier_list):
    console = Console()
    
    # Цветовая градация для тиров
    tier_colors = {
        'WW': 'bright_red',
        'W': 'red',
        'L': 'yellow',
        'LL': 'bright_yellow'
    }
    
    # Вывод заголовка с белым цветом
    console.print("Tier-list:", style="white bold")
    console.print("=" * 20, style="white bold")
    
    for tier, names in tier_list.items():
        if names:
            # Выводим тиро с соответствующим цветом
            console.print(f"\n{tier}:", style=tier_colors[tier])
            for name in names:
                # Используем Text для точного контроля цвета
                text = Text(f"  - {name}")
                text.stylize(tier_colors[tier])
                console.print(text)
        else:
            # Для пустых тиров белый цвет
            console.print(f"\n{tier}:", style="white")

if __name__ == "__main__":
    entries = parse_markdown_table("results.md")
    filtered_tier_list = filter_and_sort_entries(entries)
