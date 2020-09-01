#!/usr/bin/gawk -f
#
# Translates OPeNDAP bes.logs into JSON

BEGIN { FS="\\|&\\|" } 
# Prints valid logs
{if ($3 == "OLFS") print "{" \
"\x22time\x22:" "\x22" $1 "\x22," \
"\x22pid\x22:" "\x22" $2 "\x22," \
"\x22host\x22:" "\x22" $4 "\x22," \
"\x22user_agent\x22:" "\x22" $5 "\x22," \
"\x22session_id\x22:" "\x22" $6 "\x22," \
"\x22user_id\x22:" "\x22" $7 "\x22," \
"\x22start_time\x22:" "\x22" $8 "\x22," \
"\x22" "duration\x22:" "\x22" $9 "\x22," \
"\x22http_verb\x22:" "\x22" $10 "\x22," \
"\x22url_path\x22:" "\x22" $11 "\x22," \
"\x22query\x22:" "\x22" $12 "\x22," \
"\x22" "bes_cmd\x22:" "\x22" $14 "\x22," \
"\x22protocol\x22:" "\x22" $15 "\x22," \
"\x22local_path\x22:" "\x22" $16 "\x22}";
#Prints error logs
else print "{" \
"\x22time\x22:" "\x22" $1 "\x22," \
"\x22pid\x22:" "\x22" $2 "\x22," \
"\x22message\x22:" "\x22" $3 "\x22}";
}
