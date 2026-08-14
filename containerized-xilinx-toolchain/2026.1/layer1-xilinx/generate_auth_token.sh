#!/usr/bin/expect -f

# Fill in the email and password here.
# This script should NOT be copied into the final image to avoid leaking
# credentials through Docker layer history.
# Instead, it's placed inside the /temp directory which is mounted only during
# the build process so it won't be committed into the image.
set email "your@email.com"
set password "your_password"

set timeout 60

# xsetup expects an interactive terminal environment. Docker build steps
# normally have TERM=dumb and no controlling TTY, so explicitly provide the
# terminal environment expected by the installer.
set env(TERM) "xterm"
set env(COLORTERM) "truecolor"
set stty_init "rows 51 columns 179"

log_user 1

# Run through bash so the terminal environment is inherited by xsetup.
spawn bash -c {./xsetup -b AuthTokenGen}

puts "Waiting for email prompt..."
expect {
    -re {E-mail Address:\s*} {
        puts "Got email prompt"
        send -- "$email\r"
    }
    timeout {
        puts stderr "ERROR: Timed out waiting for email prompt"
        puts stderr "Last output: $expect_out(buffer)"
        exit 1
    }
    eof {
        puts stderr "ERROR: xsetup exited before email prompt"
        exit 1
    }
}

puts "Waiting for password prompt..."
expect {
    -re {Password:\s*} {
        puts "Got password prompt"
        send -- "$password\r"
    }
    timeout {
        puts stderr "ERROR: Timed out waiting for password prompt"
        puts stderr "Last output: $expect_out(buffer)"
        exit 1
    }
    eof {
        puts stderr "ERROR: xsetup exited before password prompt"
        exit 1
    }
}

puts "Waiting for token generation..."
expect {
    -re {Saved authentication token file successfully.*} {
        puts "Token generation completed successfully."
    }
    -re {Generating authentication token.*} {
        puts "Token generation started..."
        exp_continue
    }
    timeout {
        puts stderr "ERROR: Timed out waiting for token generation"
        puts stderr "Last output: $expect_out(buffer)"
        exit 1
    }
    eof {
        puts stderr "ERROR: xsetup exited before success message"
        exit 1
    }
}

expect eof

set auth_file "$env(HOME)/.Xilinx/wi_authentication_key"

if {[file exists $auth_file]} {
    puts "Authentication file was generated successfully at $auth_file"
} else {
    puts stderr "ERROR: Authentication file was NOT found: $auth_file"
    exit 1
}
