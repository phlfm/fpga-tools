#!/usr/bin/expect

# Disable the global timeout so `expect` waits indefinitely by default
set timeout -1

# Fill in the email and password here.
# This script should NOT be copied into the final image to avoid leaking
# credentials through Docker layer history.
# Instead, it's placed inside the /temp directory which is mounted only during
# the build process so it won't be committed into the image.
set email "your@email.com"
set password "your_password"

# Start the token generation process
spawn ./xsetup -b AuthTokenGen

# Wait for email prompt and send the email
expect "E-mail Address:"
send "$email\r"

# Set a shorter timeout for the password prompt to fail fast if it hangs
set timeout 10

# Wait for password prompt and send the password
expect "Password:"
send "$password\r"

# Confirm success based on expected output or exit with error
expect {
    "Saved authentication token file successfully*" {
        puts "Token generation completed successfully."
    }
    timeout {
        puts "Timeout: Token generation may have failed."
        exit 1
    }
}

# Wait for the child process to fully exit
expect eof

# Verify the authentication file exists as a final check
set home [exec echo $env(HOME)]
set auth_file "$home/.Xilinx/wi_authentication_key"
if {[file exists $auth_file]} {
    puts "Authentication file was generated successfully at $auth_file"
} else {
    # Mount the base image and run the AuthTokenGen command by hand and
    # check what's going wrong.
    # An alternative is to see the logs in ~/.Xilinx/xinstall/xinstall*.log
    puts "Authentication file was NOT found. Something might've gone wrong."
    exit 1
}
