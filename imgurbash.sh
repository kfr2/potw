#!/bin/bash

# imgur upload script by Kevin Richardson <kevin@magically.us>
# modified from imgur script by Bart Nagel <bart@tremby.net>
# I [Bart Nagel] release this as public domain. Do with it what you will.

# Required: curl

# put your api key here. sign up for one at:
#  http://imgur.com/register/api_anon
apikey=""

# function to output usage instructions
function usage {
	echo "Usage: $(basename $0) <filename>
Uploads an image to imgur and output its new URL hash and delete page hash as an SQL insert statement." 
}


# check arguments
if [ "$1" = "-h" -o "$1" = "--help" ]; then
	usage
	exit 0
elif [ $# -ne 1 ]; then
	if [ $# == 0 ]; then
		echo "No file specified" >&2
	else
		echo "Unexpected arguments" >&2
	fi
	usage
	exit 16
elif [ ! -f "$1" ]; then
	echo "File \"$1\" not found" >&2
	exit 1
fi

# check curl is available
which curl >/dev/null 2>/dev/null || {
	echo "Couln't find curl, which is required." >&2
	exit 17
}

# upload the image
response=$(curl -F "key=$apikey" -H "Expect: " -F "image=@$1" \
	http://api.imgur.com/2/upload.xml 2>/dev/null)
# the "Expect: " header is to get around a problem when using this through the
# Squid proxy. Not sure if it's a Squid bug or what.
if [ $? -ne 0 ]; then
	echo "Upload failed" >&2
	exit 2
elif [ $(echo $response | grep -c "<error>") -gt 0 ]; then
	echo "Error message from imgur:" >&2
	echo $response | sed -r 's/.*<message>(.*)<\/message>.*/\1/' >&2
	exit 3
fi


# parse the response and output our stuff
hash=$(echo $response | sed -r 's/.*<hash>(.*)<\/hash>.*/\1/')
deletehash=$(echo $response | sed -r 's/.*<deletehash>(.*)<\/deletehash>.*/\1/')
date_added=`date +%s`

output="INSERT INTO images ('hash', 'delete_hash', 'date_added') VALUES ('${hash}', '${deletehash}', ${date_added});"


echo $output
