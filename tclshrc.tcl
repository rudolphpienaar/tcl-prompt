# ~/.tclshrc - Interactive enhancements for tclsh
#
# This script configures a powerline-style prompt with color and the current
# path, providing support for tclreadline. It's designed to be modular,
# readable, and robust against common environment issues.

# Check if the shell is interactive before proceeding.
if {[info exists tcl_interactive] && $tcl_interactive} {
    # Flag to enable/disable colors.
    set _no_color 0
    variable _color

    proc _colors_setup {} {
        variable _color
        variable _no_color
        if {$_no_color} {
            array set _color {}
        } else {
            # Use 24-bit colors for the prompt segments.
            array set _color {
                # Standard ANSI colors
                black          "\033\[30m"
                red            "\033\[31m"
                green          "\033\[32m"
                yellow         "\033\[33m"
                blue           "\033\[34m"
                magenta        "\033\[35m"
                cyan           "\033\[36m"
                white          "\033\[37m"
                reset          "\033\[0m"
                bold           "\033\[1m"

                # 24-bit foreground colors
                fg_white       "\033\[38;2;255;255;255m"
                fg_dark_blue   "\033\[38;2;22;22;200m"
                fg_dark_green  "\033\[38;2;0;100;0m"
                fg_dark_red    "\033\[38;2;139;0;0m"
                fg_dark_yellow "\033\[38;2;184;134;11m"
                fg_dark_cyan   "\033\[38;2;0;139;139m"
                fg_dark_orange "\033\[38;2;255;120;0m"
                fg_purple      "\033\[38;2;138;43;226m"

                # 24-bit background colors
                bg_black       "\033\[48;2;0;0;0m"
                bg_dark_blue   "\033\[48;2;22;22;200m"
                bg_dark_green  "\033\[48;2;0;100;0m"
                bg_dark_red    "\033\[48;2;139;0;0m"
                bg_dark_yellow "\033\[48;2;184;134;11m"
                bg_dark_cyan   "\033\[48;2;0;139;139m"
                bg_dark_orange "\033\[48;2;255;120;0m"
                bg_purple      "\033\[48;2;138;43;226m"
            }
        }
    }

    proc colorize {attribute_list text} {
        variable _color
        variable _no_color
        if {$_no_color} {return $text}

        set ansi_codes ""
        foreach attr $attribute_list {
            if {[info exists _color($attr)]} {
                append ansi_codes $_color($attr)
            }
        }

        if {$ansi_codes eq ""} {
            return $text
        }
        return "\001${ansi_codes}\002${text}\001${_color(reset)}\002"
    }

    # --- Central Theme Definition ---
    # Change values here, referencing the colors above, for customization.
    # I know it's a bit primitive, but it's a start!
    array set prompt_theme {
        default_fg    fg_white
        default_style bold

        datetime_bg   bg_dark_cyan
        datetime_fg   fg_white

        tcl_bg        bg_purple
        tcl_fg        fg_white

        user_bg       bg_dark_blue
        user_fg       fg_white

        arch_bg       bg_dark_yellow
        arch_fg       fg_white

        path_bg       bg_dark_green
        path_fg       fg_white

        git_bg        bg_dark_red
        git_fg        fg_white

        load_bg       bg_dark_orange
        load_fg       fg_white
    }

    # --- Helper Procedures ---

    proc _get_git_status {} {
        if {[catch {exec git rev-parse --is-inside-work-tree} out] || [string trim $out] ne "true"} {return ""}
        if {[catch {exec git symbolic-ref --short HEAD} branch]} {
            if {[catch {exec git rev-parse --short HEAD} branch]} {set branch "unknown"}
        }
        set branch [string trim $branch]
        set dirty_char ""
        if {[catch {exec git status --porcelain} status] == 0 && $status ne ""} {set dirty_char "*"}
        return "\uE0A0 $branch$dirty_char"
    }

    proc _get_uname {} {
        if {[catch {exec uname -m} arch]} {return ""}
        return "\uF108 [string trim $arch]"
    }

    proc _get_load_avg {} {
        if {[catch {exec uptime} uptime_output] || ![regexp {load average(?:s)?:\s*([\d.]+)} $uptime_output -> load_1m]} {return ""}
        return "\uF0E7 [string trim $load_1m]"
    }

    proc _get_datetime {} {
        return "\uF017 [clock format [clock seconds] -format "%H:%M:%S"]"
    }

    proc _get_tcl_version {} {
        return "\uF41C [info patchlevel]" ;# Tcl Feather icon
    }

    # Renders a single separator segment.
    proc _render_separator {segparts_var i separator_char prev_bg} {
        upvar 2 $segparts_var segparts
        set num_segments [llength $segparts]

        set next_bg "bg_black"
        for {set j [expr {$i + 1}]} {$j < $num_segments} {incr j} {
            set next_element [lindex $segparts $j]
            if {[llength $next_element] >= 2} {
                set next_colors [lindex $next_element 1]
                foreach color $next_colors {
                    if {[string match "bg_*" $color]} {
                        set next_bg $color
                        break
                    }
                }
                break
            }
        }

        set prev_fg [regsub {^bg_} $prev_bg {fg_}]
        set separator_colors [list $next_bg $prev_fg]
        return [colorize $separator_colors $separator_char]
    }

    # Orchestrates the rendering of all prompt segments.
    proc segments_render {segments} {
        upvar 1 $segments segparts
        set prompt ""
        set prev_bg "bg_black"
        set num_segments [llength $segparts]
        for {set i 0} {$i < $num_segments} {incr i} {
            set element [lindex $segparts $i]
            if {[llength $element] >= 2} {
                set key [lindex $element 0]
                set colors [lindex $element 1]
                upvar 1 $key info

                # Add a space to the front and back of the text for padding.
                set info " $info "

                append prompt [colorize $colors $info]
                foreach color $colors {
                    if {[string match "bg_*" $color]} {
                        set prev_bg $color
                        break
                    }
                }
            } else {
                set separator_char [lindex $element 0]
                append prompt [_render_separator $segments $i $separator_char $prev_bg]
            }
        }
        return "$prompt"
    }

    # Set up tclreadline if the package is available.
    if {![catch {package require tclreadline} err]} {
        proc ::tclreadline::prompt1 {} {
            variable _color
            global prompt_theme ;# FIX 1: Use 'global' to import the theme array

            # --- Get all prompt data ---
            set user [string trim [exec whoami]]
            set host [string trim [exec hostname]]
            set path [pwd]
            set home_dir [string trim $::env(HOME)]
            if {[string equal $path $home_dir]} {set path "~"}

            set user_host "\uF007 $user@$host"
            set datetime_info [_get_datetime]
            set uname_info [_get_uname]
            set git_info [_get_git_status]
            set load_info [_get_load_avg]
            set tcl_version [_get_tcl_version]

            # --- Dynamically build the segments list ---
            set segments {}

            # FIX 2: Create a base style list and use list/concat to force substitution
            set base_style [list $prompt_theme(default_fg) $prompt_theme(default_style)]

            # [datetime]
            lappend segments [list datetime_info [concat [list $prompt_theme(datetime_bg)] $base_style]]
            lappend segments { "\uE0B0" }

            # [tcl_version]
            lappend segments [list tcl_version [concat [list $prompt_theme(tcl_bg)] $base_style]]
            lappend segments { "\uE0B0" }

            # [user@host]
            lappend segments [list user_host [concat [list $prompt_theme(user_bg)] $base_style]]
            lappend segments { "\uE0B0" }

            # [arch]
            if {$uname_info ne ""} {
                lappend segments [list uname_info [concat [list $prompt_theme(arch_bg)] $base_style]]
                lappend segments { "\uE0B0" }
            }

            # [path]
            lappend segments [list path [concat [list $prompt_theme(path_bg)] $base_style]]

            # [git]
            if {$git_info ne ""} {
                lappend segments { "\uE0B0" }
                lappend segments [list git_info [concat [list $prompt_theme(git_bg)] $base_style]]
            }

            # [load]
            if {$load_info ne ""} {
                lappend segments { "\uE0B0" }
                lappend segments [list load_info [concat [list $prompt_theme(load_bg)] $base_style]]
            }

            lappend segments { "\uE0B0" } ;# Final separator

            # --- Render the prompt ---
            return "[segments_render segments]\n\$ "
        }

        _colors_setup
        ::tclreadline::Loop
    } else {
        # Fallback prompt for when tclreadline is not available.
        proc tcl_prompt1 {} {
            set user [string trim [exec whoami]]
            set host [string trim [exec hostname]]
            set path [pwd]
            set home_dir [string trim $::env(HOME)]
            if {[string equal $path $home_dir]} {set path "~"}
            puts -nonewline "$user@$host:$path > "
            return
        }
    }
}
