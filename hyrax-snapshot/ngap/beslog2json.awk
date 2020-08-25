#!/usr/bin/awk -f
#
# Translates OPeNDAP bes.logs into JSON

BEGIN { FS="\\\|&\\\|" } 
# Prints valid logs
{if ($3 == "OLFS") print "{\n" \
"\x22time\x22:" "\x22" $1 "\x22,\n" \
"\x22pid\x22:" "\x22" $2 "\x22,\n" \
"\x22host\x22:" "\x22" $4 "\x22,\n" \
"\x22user_agent\x22:" "\x22" $5 "\x22,\n" \
"\x22session_id\x22:" "\x22" $6 "\x22,\n" \
"\x22user_id\x22:" "\x22" $7 "\x22,\n" \
"\x22startTime\x22:" "\x22" $8 "\x22,\n" \
"\x22" "duration\x22:" "\x22" $9 "\x22,\n" \
"\x22http_verb\x22:" "\x22" $10 "\x22,\n" \
"\x22url_path\x22:" "\x22" $11 "\x22,\n" \
"\x22query\x22:" "\x22" $12 "\x22,\n" \
"\x22" "bes_cmd\x22:" "\x22" $14 "\x22,\n" \
"\x22protocol\x22:" "\x22" $15 "\x22,\n" \
"\x22local_path\x22:" "\x22" $16 "\x22\n}"
#Prints error logs
else print "{\n" \
"\x22time\x22:" "\x22" $1 "\x22,\n" \
"\x22pid\x22:" "\x22" $2 "\x22,\n" \
"\x22message\x22:" "\x22" $3 "\x22,\n}" \
}