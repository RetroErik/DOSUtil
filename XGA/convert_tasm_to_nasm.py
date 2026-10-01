#!/usr/bin/env python3
"""Convert TASM syntax to NASM syntax"""

import re
import sys

filepath = r"Demoes vith source code\Amnesia\Amnesia.asm"

# Read the file
with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

print(f"Processing {filepath}...")
original_size = len(content)

# Remove 'ptr' keyword from memory operands
# Pattern: (byte|word|dword)\s+ptr\s+
content = re.sub(r'(byte|word|dword)\s+ptr\s+', r'\1 ', content)
print("✓ Removed 'ptr' keyword from memory operands")

# Fix dword/word/byte [variable+offset] patterns
# In TASM: dword ptr variable[offset] or dword ptr [variable+offset]
# In NASM: dword [variable+offset]
# This is already mostly handled above, but let's ensure consistency

# Write back
with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

new_size = len(content)
print(f"✓ File converted: {original_size} → {new_size} bytes")
print(f"✓ Saved to {filepath}")
