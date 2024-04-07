#
# Translates OPeNDAP bes.logs into JSON
#
# Log Fields type==request
# 1601646465|&|2122|&|request|&|OLFS|&|0:0:0:0:0:0:0:1|&|USER_AGENT|&|92F3C71F959B56515C98A09088CA2A8E
#    1          2        3       4           5              6               7
# |&|-|&|1601646465304|&|18|&|HTTP-GET|&|/opendap/hyrax/data/nc/fnoc1.nc.dds|&|u|&|BES
#    8     9             10     11              12                             13   14
# |&|get.dds|&|dap2|&|/Users/ndp/OPeNDAP/hyrax/build/share/hyrax/data/nc/fnoc1.nc|&|u
#      15       16                              17                                  18
#
# 1601642669|&|2122|&|timing|&|TimingFields
# 1601642669|&|2122|&|verbose|&|MessageField
# 1601642679|&|2122|&|info|&|MessageField
# 1601642679|&|2122|&|error|&|MessageField
# 1601642679|&|2122|&|request|&|RequestFields
#
# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
BEGIN {
    FS="\\|&\\|";

    if(debug!="true"){
         debug="false";
    }

    if(pretty!="true"){
        pretty="false";
    }

    if(pretty=="true"){
        n="\n";
        indent="    ";
    }
}
{
    # First, escape all of the double quotes in the input line, because json.
    gsub(/\"/, "\\\"");

    # Look for a leading [ which indicates an incorrectly constructed log entry
    if($0 ~ /^\[/){
        # This is a logging error.
        # Make an error log entry about the error in the log.
        printf("{ %s%s\"time\": -1", n, indent, now);
        printf(", %s%s\"pid\": -1", n, indent);
        printf(", %s%s\"type\": \"error\"", n, indent);
        msg = "OUCH! Input log line "NR" appears to use [ and ] to delimit values. Line: "$0;
        printf(", %s%s\"message\": \"%s\"} %s", n, indent, msg, n);
    }
    else if($0.length() != 0) { # Don't process an empty line...

        if(debug=="true"){
            print "------------------------------------------------";
            print $0;
        }
        printf("{ %s", n);
        printf("%s\"time\": %s", indent, $1);
        printf(", %s%s\"pid\": %s",  n, indent, $2, n);
        type=$3;
        printf(", %s%s\"type\": \"%s\"",  n, indent, type, n);

        if(type=="request"){
            # Field $4 aleays has the value OLFS. It marks the beginning
            # of things sent by the OLFS. The tag not needed for ngap logs.
            #printf(", %s%s\"OLFS\": \"%s\"", n, indent,$4);

            # ip-address of requesting client's system.
            printf(", %s%s\"client_ip\": \"%s\"", n, indent,$5);

            # The value of the User-Agent request header sent from the client.
            printf(", %s%s\"user_agent\": \"%s\"", n, indent,$6);

            # The session id, if present.
            printf(", %s%s\"session_id\": \"%s\"", n, indent,$7);

            # The user's user id, if a user is logged in.
            printf(", %s%s\"user_id\": \"%s\"", n, indent,$8);

            # The time the the request was received.
            printf(", %s%s\"start_time\": %s", n, indent,$9);

            # We are not so sure what this number is...
            printf(", %s%s\"duration\": %s", n, indent,$10);

            # The HTTP verb of the request (GET, POST, etc)
            printf(", %s%s\"http_verb\": \"%s\"", n, indent,$11);

            # The path component of the requested resource.
            printf(", %s%s\"url_path\": \"%s\"", n, indent,$12);

            # The query string, if any, submitted with the request.
            printf(", %s%s\"query_string\": \"%s\"", n, indent,$13);

            # Field 14 is a field that indicates the following fields orginated
            # in the BES, it is not semantically important to NGAP
            # printf(", %s%s\"bes\": \"%s\"", n, indent,$14);

            # The type of BES action/request/command invoked by the request
            printf(", %s%s\"bes_request\": \"%s\"", n, indent,$15);

            # The DAP protocl
            printf(", %s%s\"dap_version\": \"%s\"", n, indent,$16);

            # The local file path to the resource.
            printf(", %s%s\"local_path\": \"%s\"", n, indent,$17);

            # Field 18 is a duplicate of field 13 and if the query string is absent
            # then field 18 will be missing entirely.
            printf(", %s%s\"constraint_expression\": \"%s\"", n, indent, $18);

        }
        else if(type=="info" || type=="error" || type=="verbose" ){
            printf(", %s%s\"message\": \"%s\"",  n, indent, $4);
        }
        else if(type == "timing"){

            time_type = $4;

            if(time_type=="start_us"){
                # 1601642669|&|2122|&|timing|&|start_us|&|1601642669945133|&|-|&|TIMER_NAME
                #      1         2      3        4             5             6      7
                printf(", %s%s\"start_time_us\": %s", n, indent, $5);
                printf(", %s%s\"req_id\": \"%s\"", n, indent, $6);
                printf(", %s%s\"name\": \"%s\"", n, indent, $7);
            }
            else if(time_type=="elapsed_us"){
                # 1601653546|&|7096|&|timing|&|elapsed_us|&|2169|&|start_us|&|1601653546269617|&|stop_us
                #     1          2      3         4          5        6            7                8
                # |&|1601653546271786|&|ReqId|&|TIMER_NAME
                #          9              10       11
                printf(", %s%s\"elapsed_time_us\": %s", n, indent, $5);
                printf(", %s%s\"start_time_us\": %s", n, indent, $7);
                printf(", %s%s\"stop_time_us\": %s", n, indent, $9);
                printf(", %s%s\"req_id\": \"%s\"", n, indent, $10);
                printf(", %s%s\"name\": \"%s\"", n, indent, $11);

            }
            else {
                printf(", %s%s\"LOG_ERROR\": \"FAILED to process: %s\"", n , indent, $0);
            }
        }
        printf("%s}\n", n);
    }
    else {
        if(debug == "true"){
            print "# Line "NR" is blank, ignored."
        }
    }
}
