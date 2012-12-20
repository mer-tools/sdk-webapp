#!/bin/env ruby

case ARGV[0]
when "--sdk"
	case ARGV[1]
	when "--version"
		puts "SDK_MOCK_VERSION"
	else
		puts "UNKNOWN_ARGV1"
		exit 1
	end
when "--target"
	case ARGV[1]
	when "--list"
		puts "TARGET1\nTARGET2\nDEFAULT_TARGET\n"
	else
		puts "UNKNOWN_ARGV1"
		exit 1
	end
when "--toolchain"
	case ARGV[1]
	when "--list"
		puts "TOOLCHAIN1,\nTOOLCHAIN2,i\nTOOLCHAIN3\n"
	else
		puts "UNKNOWN_ARGV1"
		exit 1
	end
else
	puts "UNKNOWN_ARGV0"
	exit 1
end





