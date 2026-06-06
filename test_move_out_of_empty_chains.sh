#!/usr/bin/env bash
set -euo pipefail

# Test suite for move-out-of-empty-chains.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/move-out-of-empty-chains.sh"
TEST_TMPDIR=""
PASSED=0
FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Setup
setup_test_dir() {
  TEST_TMPDIR="$(mktemp -d)"
  echo "Test directory: $TEST_TMPDIR"
}

# Cleanup
teardown_test_dir() {
  rm -rf "$TEST_TMPDIR"
}

# Assertion helpers
assert_file_exists() {
  local file="$1"
  if [[ -f "$file" ]]; then
    echo -e "${GREEN}✓${NC} File exists: $file"
    ((PASSED++))
  else
    echo -e "${RED}✗${NC} File NOT found: $file"
    ((FAILED++))
  fi
}

assert_file_not_exists() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo -e "${GREEN}✓${NC} File correctly removed: $file"
    ((PASSED++))
  else
    echo -e "${RED}✗${NC} File still exists: $file"
    ((FAILED++))
  fi
}

assert_dir_exists() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    echo -e "${GREEN}✓${NC} Directory exists: $dir"
    ((PASSED++))
  else
    echo -e "${RED}✗${NC} Directory NOT found: $dir"
    ((FAILED++))
  fi
}

assert_dir_not_exists() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    echo -e "${GREEN}✓${NC} Directory correctly removed: $dir"
    ((PASSED++))
  else
    echo -e "${RED}✗${NC} Directory still exists: $dir"
    ((FAILED++))
  fi
}

print_tree() {
  local dir="${1:-.}"
  echo "Directory structure:"
  find "$dir" -print | sort | sed 's|[^/]*/| |g'
}

# Test 1: Simple nested structure
test_simple_nested() {
  echo -e "\n${YELLOW}Test 1: Simple nested structure${NC}"
  setup_test_dir
  
  mkdir -p "$TEST_TMPDIR/a/b/c"
  echo "content" > "$TEST_TMPDIR/a/b/c/file.txt"
  
  print_tree "$TEST_TMPDIR"
  
  bash "$SCRIPT" "$TEST_TMPDIR"
  
  echo "After running script:"
  print_tree "$TEST_TMPDIR"
  
  assert_file_exists "$TEST_TMPDIR/file.txt"
  assert_dir_not_exists "$TEST_TMPDIR/a/b/c"
  assert_dir_not_exists "$TEST_TMPDIR/a/b"
  assert_dir_not_exists "$TEST_TMPDIR/a"
  
  teardown_test_dir
}

# Test 2: Multiple files in nested dirs
test_multiple_files() {
  echo -e "\n${YELLOW}Test 2: Multiple files in nested directories${NC}"
  setup_test_dir
  
  mkdir -p "$TEST_TMPDIR/a/b"
  mkdir -p "$TEST_TMPDIR/c/d"
  echo "file1" > "$TEST_TMPDIR/a/b/file1.txt"
  echo "file2" > "$TEST_TMPDIR/c/d/file2.txt"
  
  print_tree "$TEST_TMPDIR"
  
  bash "$SCRIPT" "$TEST_TMPDIR"
  
  echo "After running script:"
  print_tree "$TEST_TMPDIR"
  
  assert_file_exists "$TEST_TMPDIR/file1.txt"
  assert_file_exists "$TEST_TMPDIR/file2.txt"
  assert_dir_not_exists "$TEST_TMPDIR/a"
  assert_dir_not_exists "$TEST_TMPDIR/c"
  
  teardown_test_dir
}

# Test 3: Mixed structure (some empty, some not)
test_mixed_structure() {
  echo -e "\n${YELLOW}Test 3: Mixed structure with siblings${NC}"
  setup_test_dir
  
  mkdir -p "$TEST_TMPDIR/keep/subdir"
  mkdir -p "$TEST_TMPDIR/remove/empty"
  echo "important" > "$TEST_TMPDIR/keep/file.txt"
  echo "moveable" > "$TEST_TMPDIR/remove/empty/file.txt"
  
  print_tree "$TEST_TMPDIR"
  
  bash "$SCRIPT" "$TEST_TMPDIR"
  
  echo "After running script:"
  print_tree "$TEST_TMPDIR"
  
  assert_file_exists "$TEST_TMPDIR/keep/file.txt"
  assert_dir_exists "$TEST_TMPDIR/keep"
  assert_file_exists "$TEST_TMPDIR/moveable"
  assert_dir_not_exists "$TEST_TMPDIR/remove"
  
  teardown_test_dir
}

# Test 4: Collision handling (duplicate filenames)
test_collision_handling() {
  echo -e "\n${YELLOW}Test 4: Collision handling${NC}"
  setup_test_dir
  
  mkdir -p "$TEST_TMPDIR/a/b"
  echo "original" > "$TEST_TMPDIR/file.txt"
  echo "duplicate" > "$TEST_TMPDIR/a/b/file.txt"
  
  print_tree "$TEST_TMPDIR"
  
  bash "$SCRIPT" "$TEST_TMPDIR"
  
  echo "After running script:"
  print_tree "$TEST_TMPDIR"
  
  assert_file_exists "$TEST_TMPDIR/file.txt"
  assert_file_exists "$TEST_TMPDIR/file.txt.1"
  
  teardown_test_dir
}

# Test 5: Deep nesting
test_deep_nesting() {
  echo -e "\n${YELLOW}Test 5: Deep nesting (5 levels)${NC}"
  setup_test_dir
  
  mkdir -p "$TEST_TMPDIR/a/b/c/d/e"
  echo "deep" > "$TEST_TMPDIR/a/b/c/d/e/deep.txt"
  
  print_tree "$TEST_TMPDIR"
  
  bash "$SCRIPT" "$TEST_TMPDIR"
  
  echo "After running script:"
  print_tree "$TEST_TMPDIR"
  
  assert_file_exists "$TEST_TMPDIR/deep.txt"
  assert_dir_not_exists "$TEST_TMPDIR/a"
  
  teardown_test_dir
}

# Test 6: Already flat structure (no-op)
test_already_flat() {
  echo -e "\n${YELLOW}Test 6: Already flat structure (no changes needed)${NC}"
  setup_test_dir
  
  echo "file1" > "$TEST_TMPDIR/file1.txt"
  echo "file2" > "$TEST_TMPDIR/file2.txt"
  mkdir -p "$TEST_TMPDIR/dir_with_content"
  echo "content" > "$TEST_TMPDIR/dir_with_content/file3.txt"
  
  print_tree "$TEST_TMPDIR"
  
  bash "$SCRIPT" "$TEST_TMPDIR"
  
  echo "After running script:"
  print_tree "$TEST_TMPDIR"
  
  assert_file_exists "$TEST_TMPDIR/file1.txt"
  assert_file_exists "$TEST_TMPDIR/file2.txt"
  assert_dir_exists "$TEST_TMPDIR/dir_with_content"
  assert_file_exists "$TEST_TMPDIR/dir_with_content/file3.txt"
  
  teardown_test_dir
}

# Test 7: Empty directories only (no files)
test_empty_dirs_only() {
  echo -e "\n${YELLOW}Test 7: Empty directories only${NC}"
  setup_test_dir
  
  mkdir -p "$TEST_TMPDIR/a/b/c"
  
  print_tree "$TEST_TMPDIR"
  
  bash "$SCRIPT" "$TEST_TMPDIR"
  
  echo "After running script:"
  print_tree "$TEST_TMPDIR"
  
  assert_dir_not_exists "$TEST_TMPDIR/a"
  
  teardown_test_dir
}

# Test 8: Hidden files
test_hidden_files() {
  echo -e "\n${YELLOW}Test 8: Hidden files${NC}"
  setup_test_dir
  
  mkdir -p "$TEST_TMPDIR/a/b"
  echo "hidden" > "$TEST_TMPDIR/a/b/.hidden"
  echo "visible" > "$TEST_TMPDIR/a/b/visible.txt"
  
  print_tree "$TEST_TMPDIR"
  
  bash "$SCRIPT" "$TEST_TMPDIR"
  
  echo "After running script:"
  print_tree "$TEST_TMPDIR"
  
  assert_file_exists "$TEST_TMPDIR/.hidden"
  assert_file_exists "$TEST_TMPDIR/visible.txt"
  assert_dir_not_exists "$TEST_TMPDIR/a"
  
  teardown_test_dir
}

# Run all tests
run_all_tests() {
  echo -e "${YELLOW}=====================================${NC}"
  echo -e "${YELLOW}Testing: move-out-of-empty-chains.sh${NC}"
  echo -e "${YELLOW}=====================================${NC}"
  
  test_simple_nested
  test_multiple_files
  test_mixed_structure
  test_collision_handling
  test_deep_nesting
  test_already_flat
  test_empty_dirs_only
  test_hidden_files
  
  echo -e "\n${YELLOW}=====================================${NC}"
  echo -e "${YELLOW}Test Results${NC}"
  echo -e "${YELLOW}=====================================${NC}"
  echo -e "${GREEN}Passed: $PASSED${NC}"
  echo -e "${RED}Failed: $FAILED${NC}"
  
  if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    return 0
  else
    echo -e "${RED}Some tests failed!${NC}"
    return 1
  fi
}

run_all_tests
