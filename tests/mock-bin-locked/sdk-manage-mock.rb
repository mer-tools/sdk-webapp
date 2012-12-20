#!/bin/env ruby

case ARGV[0]
when "--sdk"
	case ARGV[1]
	when "--version"
		puts "WRONG_TEXT"
		exit 4
	else
		puts "UNKNOWN_ARGV1"
		exit 1
	end
when "--target"
	case ARGV[1]
	when "--list"
		puts "WRONG_TEXT\nWRONG_TEXT2\nWRONG_TEXT3\n"
		exit 4
	else
		puts "UNKNOWN_ARGV1"
		exit 1
	end
when "--toolchain"
	case ARGV[1]
	when "--list"
		puts "WRONG_TEXT\nWRONG_TEXT2,\nWRONG_TEXT3,i\n"
		exit 4
	else
		puts "UNKNOWN_ARGV1"
		exit 1
	end
else
	puts "UNKNOWN_ARGV0"
	exit 1
end





