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

    prefix="hyrax_";

    if(send_timing!="true"){
        send_timing="false";
    }

    if(send_info!="true"){
        send_info="false";
    }

    if(send_error!="true"){
        send_error="false";
    }

    if(send_verbose!="true"){
        send_verbose="false";
    }


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
        if ( send_error=="true") {
            # Make an special error log entry about the error in the log.
            printf ("{ %s%s\"%stime\": -1", n, indent, prefix);
            printf (", %s%s\"%spid\": -1", n, indent, prefix);
            printf (", %s%s\"%stype\": \"error\"", n, indent, prefix);
            msg = "OUCH! Input log line "NR" appears to use [ and ] to delimit values. Line: "$0;
            printf (", %s%s\"%smessage\": \"%s\"} %s", n, indent, prefix, msg, n);
        }
    }
    else if($0.length() != 0) { # Don't process an empty line...

        if(debug=="true"){
            print "------------------------------------------------";
            print $0;
        }
        type=$3;
        if(type=="request"){
            print_opener();

            # Field $4 aleays has the value OLFS. It marks the beginning
            # of things sent by the OLFS. The tag not needed for ngap logs.
            #printf(", %s%s\"%sOLFS\": \"%s\"", n, indent, prefix, $4);

            # ip-address of requesting client's system.
            printf(", %s%s\"%sclient_ip\": \"%s\"", n, indent, prefix, $5);

            # The value of the User-Agent request header sent from the client.
            printf(", %s%s\"%suser_agent\": \"%s\"", n, indent, prefix, $6);

            # The session id, if present.
            printf(", %s%s\"%ssession_id\": \"%s\"", n, indent, prefix, $7);

            # The user's user id, if a user is logged in.
            printf(", %s%s\"%suser_id\": \"%s\"", n, indent, prefix, $8);

            # The time the the request was received.
            printf(", %s%s\"%sstart_time\": %s", n, indent, prefix, $9);

            # We are not so sure what this number is...
            printf(", %s%s\"%sduration\": %s", n, indent, prefix, $10);

            # The HTTP verb of the request (GET, POST, etc)
            printf(", %s%s\"%shttp_verb\": \"%s\"", n, indent, prefix, $11);

            # The path component of the requested resource.
            printf(", %s%s\"%surl_path\": \"%s\"", n, indent, prefix, $12);

            # The query string, if any, submitted with the request.
            printf(", %s%s\"%squery_string\": \"%s\"", n, indent, prefix, $13);

            # Field 14 is a field that indicates the following fields orginated
            # in the BES, it is not semantically important to NGAP
            # printf(", %s%s\"%sbes\": \"%s\"", n, indent, prefix, $14);

            # The type of BES action/request/command invoked by the request
            printf(", %s%s\"%sbes_request\": \"%s\"", n, indent, prefix, $15);

            # The DAP protocl
            printf(", %s%s\"%sdap_version\": \"%s\"", n, indent, prefix, $16);

            # The local file path to the resource.
            printf(", %s%s\"%slocal_path\": \"%s\"", n, indent, prefix, $17);

            # Field 18 is a duplicate of field 13 and if the query string is absent
            # then field 18 will be missing entirely.
            printf(", %s%s\"%sconstraint_expression\": \"%s\"", n, indent, prefix, $18);

            print_closer();
        }
        else if(type=="info" && send_info=="true"){
            print_opener();
            printf(", %s%s\"%smessage\": \"%s\"",  n, indent,  prefix, $4);
            print_closer();
        }
        else if(type=="error" && send_error=="true"){
            print_opener();
            printf(", %s%s\"%smessage\": \"%s\"",  n, indent,  prefix, $4);
            print_closer();
        }
        else if(type=="verbose" && send_verbose=="true"){
            print_opener();
            printf(", %s%s\"%smessage\": \"%s\"",  n, indent,  prefix, $4);
            print_closer();
        }
        else if(type == "timing" && send_timing=="true"){

            time_type = $4;

            if(time_type=="start_us"){
                # 1601642669|&|2122|&|timing|&|start_us|&|1601642669945133|&|-|&|TIMER_NAME
                #      1         2      3        4             5             6      7
                print_opener();
                printf(", %s%s\"%sstart_time_us\": %s", n, indent, prefix, $5);
                printf(", %s%s\"%sreq_id\": \"%s\"", n, indent, prefix, $6);
                printf(", %s%s\"%sname\": \"%s\"", n, indent, prefix, $7);
                print_closer();
            }
            else if(time_type=="elapsed_us"){
                # 1601653546|&|7096|&|timing|&|elapsed_us|&|2169|&|start_us|&|1601653546269617|&|stop_us
                #     1          2      3         4          5        6            7                8
                # |&|1601653546271786|&|ReqId|&|TIMER_NAME
                #          9              10       11
                print_opener();
                printf(", %s%s\"%selapsed_time_us\": %s", n, indent, prefix, $5);
                printf(", %s%s\"%sstart_time_us\": %s", n, indent, prefix, $7);
                printf(", %s%s\"%sstop_time_us\": %s", n, indent, prefix, $9);
                printf(", %s%s\"%sreq_id\": \"%s\"", n, indent, prefix, $10);
                printf(", %s%s\"%sname\": \"%s\"", n, indent, prefix, $11);
                print_closer();
            }
            else {
                printf(", %s%s\"%sLOG_ERROR\": \"FAILED to process: %s\"", n , indent, prefix, $0);
            }
        }
    }
    else {
        if(debug == "true"){
            print "# Line "NR" is blank, ignored."
        }
    }
}
function print_opener(){
    printf("{ %s", n);
    printf("%s\"%stime\": %s", indent, prefix, $1);
    printf(", %s%s\"%spid\": %s",  n, indent, prefix, $2);
    printf(", %s%s\"%stype\": \"%s\"",  n, indent, prefix, $3);
}

function print_closer(){
    printf("%s}\n", n);
}