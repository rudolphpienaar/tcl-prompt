# Powerline Prompt for Tcl (tclsh)

This is a modern, modular, powerline-style prompt for the standard Tcl shell (`tclsh`). It's written in pure Tcl, provides support for `tclreadline`, and is designed to be configurable and extensible.

It provides a feature-rich, visually appealing prompt without requiring any external dependencies other than `tclreadline` and a patched font.


![Screenshot of the Tcl Powerline Prompt](images/kitty-prompt.png)

---
## Features

* **Powerline-Style Segments:** Seamless, connecting segments for a modern look.
* **Git Integration:** Automatically shows your current branch and a `*` for dirty status (modified, untracked, or staged files).
* **Dynamic Segments:** Only shows relevant info (like Git status) when you're in a relevant directory.
* **Rich Info Display:**
    * Current Time
    * Tcl Version
    * User & Hostname
    * Machine Architecture (e.g., `x86_64`)
    * Current Working Directory (with `~` substitution for home)
    * 1-Minute System Load Average
* **Configurable Theme:** All segment colors are defined in a central `prompt_theme` array, making customization simple.
* **Robust Readline Integration:** Correctly renders as a non-editable prompt string in `tclreadline`.

---
## Requirements

1.  **Tcl/Tk:** A standard Tcl installation.
2.  **`tclreadline` Package:** This prompt requires the `tclreadline` package to be installed and available to Tcl.
3.  **Nerd Font / Powerline Font:** You **must** use a "Nerd Font" or another font patched with Powerline symbols. This script uses the powerline triangle (`\uE0B0`) and font icons (like the Git symbol `\uE0A0`) which will not render without a patched font.

---
## Installation

1.  Clone this repository to a permanent location on your machine (e.g., `~/src/tcl-prompt`).

2.  Add the following line to your `~/.tclshrc` file (create the file if it doesn't exist):

    ```tcl
    # Source the powerline prompt from its repository location
    # Update this path to wherever you cloned the repo
    source ~/src/tcl-prompt/tclshrc.tcl
    ```

3.  Start `tclsh` and enjoy your new prompt.

---
## Customization

To change colors, simply edit the `array set prompt_theme` definition near the top of the `tclshrc.tcl` script. All segments reference this array, allowing for easy and safe theme changes.
