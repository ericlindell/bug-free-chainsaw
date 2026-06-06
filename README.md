# move-out-of-empty-chains.sh

A Bash script that recursively moves files up directory chains when they're nested in empty folders. Perfect for cleaning up deeply nested but ultimately empty directory structures.

## Problem It Solves

When you have files buried in long chains of directories that contain nothing else:

```
root/
├── a/
│   └── b/
│       └── c/
│           └── file.txt
```

This script moves files up to the root level and removes the empty intermediate directories:

```
root/
├── file.txt
```

It repeats until no files are trapped in empty chains, handling complex scenarios like:
- Multiple separate nested structures
- Directories with actual content (leaves them alone)
- Filename collisions (appends numeric suffixes)
- Hidden files (dotfiles)
- Deep nesting (5+ levels)

## Installation

```bash
# Clone or download the script
git clone https://github.com/ericlindell/bug-free-chainsaw.git
cd bug-free-chainsaw

# Make it executable
chmod +x move-out-of-empty-chains.sh
```

## Usage

```bash
./move-out-of-empty-chains.sh /path/to/directory
```

**Default behavior** (current directory):
```bash
./move-out-of-empty-chains.sh
```

### Examples

**Example 1: Simple nested structure**
```bash
# Before
project/
├── src/
│   └── utils/
│       └── helpers/
│           └── format.js

# After running: ./move-out-of-empty-chains.sh project/
project/
├── format.js
```

**Example 2: Mixed structure (some dirs have content)**
```bash
# Before
workspace/
├── keep/
│   ├── file1.js
│   └── index.js
├── archive/
│   └── old/
│       └── backup.zip

# After running: ./move-out-of-empty-chains.sh workspace/
workspace/
├── keep/
│   ├── file1.js
│   └── index.js
├── backup.zip
```

**Example 3: Filename collision handling**
```bash
# Before
data/
├── config.json           # original file
├── settings/
│   └── config.json       # duplicate name in nested dir

# After running: ./move-out-of-empty-chains.sh data/
data/
├── config.json
├── config.json.1         # collision renamed with numeric suffix
```

## How It Works

1. **Identifies empty chains**: Walks the directory tree from deepest to shallowest
2. **Checks if directory is "empty for chain"**: 
   - Contains no regular files at its level
   - All subdirectories (if any) are themselves empty chains
3. **Moves files up**: If a directory has files and all its subdirs are empty, moves files to parent
4. **Cleans up**: Removes empty directories after moving files
5. **Repeats**: Continues until no more files can be moved up

## Features

✅ **Safe**: Only moves regular files, preserves directories with actual content  
✅ **Collision handling**: Automatically renames duplicates with numeric suffixes (.1, .2, etc.)  
✅ **Hidden file support**: Handles dotfiles correctly  
✅ **Verbose output**: Shows every move operation  
✅ **Infinite loop protection**: Max 1000 iterations (prevents edge case hangs)  
✅ **Well-tested**: 8 comprehensive test cases included  

## Testing

Run the included test suite to verify the script works on your system:

```bash
chmod +x test_move_out_of_empty_chains.sh
./test_move_out_of_empty_chains.sh
```

**Test coverage:**
- Simple nested structures
- Multiple files in different chains
- Mixed structures (some empty, some with content)
- Filename collision handling
- Deep nesting (5+ levels)
- Already-flat structures (no-op)
- Empty directories only
- Hidden files (dotfiles)

All tests create temporary directories, so they don't affect your system.

## Output Example

```
$ ./move-out-of-empty-chains.sh /tmp/messy
mv: '/tmp/messy/a/b/c/file.txt' -> '/tmp/messy/file.txt'
rmdir: removing directory, '/tmp/messy/a/b/c'
rmdir: removing directory, '/tmp/messy/a/b'
rmdir: removing directory, '/tmp/messy/a'
Completed in 1 iteration(s).
```

## Performance Notes

- **Time complexity**: O(n * d) where n = number of directories, d = average depth
- **Space complexity**: O(d) for recursion stack
- **Typical use case**: Completes in 1-3 iterations for most directory structures
- **Edge cases**: Can handle 5+ levels of nesting efficiently

## Edge Cases Handled

| Scenario | Behavior |
|----------|----------|
| Symlinks | Treated as files, moved as-is |
| Special characters in filenames | Fully supported |
| Large files | No size limitations |
| Permission denied | Fails gracefully with warning |
| Circular symlinks | Detected and skipped by find |
| Mixed file types | Only regular files moved; other types preserved |

## Common Use Cases

### Download cleanup
```bash
# Downloads folder: Downloads/project-v1/src/main.js
# After running script: Downloads/main.js
./move-out-of-empty-chains.sh ~/Downloads
```

### Archive extraction
```bash
# Extracted archive has deep structure
tar -xzf archive.tar.gz
./move-out-of-empty-chains.sh extracted_folder/
```

### Project refactoring
```bash
# Clean up deprecated deeply-nested modules
./move-out-of-empty-chains.sh src/deprecated/
```

## Limitations

- **Does not move directories**: Only regular files are relocated
- **Requires write permissions**: Must have permission to move files and remove directories
- **No undo**: Changes are permanent (but safe - no files are deleted, only moved)

## Troubleshooting

**Script doesn't find files**
- Ensure the path exists: `ls -la /path/to/directory`
- Check file permissions: `stat /path/to/file`

**Files not moving**
- Verify the script is executable: `chmod +x move-out-of-empty-chains.sh`
- Check parent directory permissions: `ls -ld /path/to/directory`

**"Permission denied" errors**
- Ensure you have write access to all directories
- May need to run with `sudo` for system directories (use with caution)

## Contributing

Found a bug? Have an improvement?
1. Test the issue with `test_move_out_of_empty_chains.sh`
2. Create an issue or pull request on GitHub

## License

MIT License - Feel free to use, modify, and distribute.

## Author

Created by [@ericlindell](https://github.com/ericlindell)

---

**Questions?** Open an issue on [GitHub](https://github.com/ericlindell/bug-free-chainsaw/issues)
