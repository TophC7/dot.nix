#!/usr/bin/env python3
import curses
import subprocess
import sys
import os
import traceback

def run_cmd(cmd):
    """Run cmd list, return (success:bool, output:str)."""
    try:
        out = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
        return True, out.decode()
    except subprocess.CalledProcessError as e:
        return False, e.output.decode()

def get_archives(repo):
    """List archives by running `borg list repo`."""
    success, out = run_cmd(["borg", "list", repo])
    if not success:
        return [], out
    archives = []
    for line in out.splitlines():
        parts = line.split(maxsplit=1)  # Split into name and rest
        if parts:
            archives.append(parts[0])
    return archives, ""

def prompt(stdscr, msg):
    curses.echo()
    h, w = stdscr.getmaxyx()
    stdscr.addstr(h-1, 0, msg)
    stdscr.clrtoeol()
    stdscr.refresh()
    inp = stdscr.getstr(h-1, len(msg)).decode()
    curses.noecho()
    return inp

def draw(stdscr, repo, archives, sel, offset, status):
    stdscr.erase()
    h, w = stdscr.getmaxyx()
    
    # Header
    header = f"Borg TUI - Repo: {repo}"
    stdscr.addstr(0, 0, header[:w-1])
    
    # If no archives, show message
    if not archives:
        stdscr.addstr(2, 0, "No backups found in repository")
        stdscr.addstr(3, 0, "(q) to quit, (r) to refresh")
    else:
        # Menu
        visible = h - 4
        for idx, arch in enumerate(archives[offset:offset+visible]):
            y = idx + 1
            line = f"{idx+offset+1:2}. {arch}"[:w-1]
            if idx+offset == sel:
                stdscr.attron(curses.A_REVERSE)
                stdscr.addstr(y, 0, line)
                stdscr.attroff(curses.A_REVERSE)
            else:
                stdscr.addstr(y, 0, line)
    
    # Help line
    help_line = "↑↓:move  d:delete  r:restore  q:quit"
    stdscr.addstr(h-3, 0, help_line[:w-1])
    
    # Status line
    stdscr.addstr(h-2, 0, status[:w-1])
    stdscr.refresh()

def main(stdscr):
    # Check if arguments are provided
    if len(sys.argv) != 2:
        stdscr.erase()
        stdscr.addstr(0, 0, "Error: Repository path not provided")
        stdscr.addstr(1, 0, "Usage: ./tui.sh /path/to/borg/repository")
        stdscr.addstr(3, 0, "Press any key to exit...")
        stdscr.refresh()
        stdscr.getch()
        return

    repo = sys.argv[1]
    curses.curs_set(0)  # Hide cursor
    
    # Check if repo exists
    if not os.path.isdir(repo):
        stdscr.addstr(0, 0, f"Error: Repository not found: {repo}")
        stdscr.addstr(1, 0, "Press any key to exit...")
        stdscr.getch()
        return
    
    # Get archive list
    archives, err = get_archives(repo)
    if err:
        stdscr.addstr(0, 0, f"Error listing archives: {err}")
        stdscr.addstr(1, 0, "Press any key to exit...")
        stdscr.getch()
        return

    sel = 0
    offset = 0
    status = "Ready"

    # Main loop
    while True:
        h, w = stdscr.getmaxyx()
        max_disp = h - 4
        
        # Handle scrolling
        if sel < offset:
            offset = sel
        elif sel >= offset + max_disp:
            offset = sel - max_disp + 1

        draw(stdscr, repo, archives, sel, offset, status)
        try:
            key = stdscr.getch()
        except KeyboardInterrupt:
            break

        # Navigation and actions
        if key in (curses.KEY_UP, ord('k')):
            if archives:
                sel = max(0, sel-1)
                status = "Moved up"
        elif key in (curses.KEY_DOWN, ord('j')):
            if archives:
                sel = min(len(archives)-1, sel+1)
                status = "Moved down"
        elif key == ord('q'):
            break
        elif key == ord('r'):
            # If 'r' is pressed with no archives, refresh list
            if not archives:
                archives, err = get_archives(repo)
                status = "Refreshed archive list"
                if err:
                    status = f"Error: {err}"
            elif archives:  # If archives exist, restore selected archive
                name = archives[sel]
                dest = prompt(stdscr, f"Restore {name} to dir: ")
                if dest:
                    # Create destination directory
                    try:
                        os.makedirs(dest, exist_ok=True)
                        status = f"Extracting {name} to {dest}..."
                        draw(stdscr, repo, archives, sel, offset, status)
                        
                        # Change to destination directory and extract
                        cwd = os.getcwd()
                        os.chdir(dest)
                        ok, out = run_cmd(["borg", "extract", f"{repo}::{name}"])
                        os.chdir(cwd)  # Return to original directory
                        
                        status = f"Restored {name} to {dest}" if ok else f"Error: {out.strip()}"
                    except Exception as e:
                        status = f"Error: {str(e)}"
                else:
                    status = "Restore cancelled - No destination provided"

        elif key == ord('d') and archives:
            name = archives[sel]
            ans = prompt(stdscr, f"Delete {name}? (y/N): ")
            if ans.lower().startswith('y'):
                # Delete with force flag
                ok, out = run_cmd(["borg", "delete", "--force", f"{repo}::{name}"])
                if ok:
                    status = f"Deleted {name}"
                    # Refresh archives list after deletion
                    archives, err = get_archives(repo)
                    sel = min(sel, max(0, len(archives)-1))
                else:
                    status = f"Error: {out.strip()}"
            else:
                status = "Delete cancelled"

# Entry point with improved error handling
if __name__ == "__main__":
    try:
        curses.wrapper(main)
    except KeyboardInterrupt:
        print("Exited Borg TUI")
    except Exception as e:
        # Log any uncaught exceptions
        with open("/tmp/borg-tui-error.log", "a") as f:
            f.write(f"{traceback.format_exc()}\n")
        print(f"Error: {str(e)}. See /tmp/borg-tui-error.log for details.")