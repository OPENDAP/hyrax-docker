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

    # A namespace prefix for our variable names, if desired.
    prefix="hyrax_";

    if(send_all=="true"){
        # Send everything as json.
        send_error="true";
        send_timing="true";
        send_info="true";
        send_verbose="true";
    }
    else{
        # Transmit error log messages.
        send_error = process_bool_value(send_error, "true");

        # Transmit timing data.
        send_timing = process_bool_value(send_timing, "false");

        # Transmit info log messages..
        send_info = process_bool_value(send_info, "false");

        # Transmit verbose  log messages.
        send_verbose = process_bool_value(send_verbose, "false");
    }

    # Debuggin Mode
    if(debug!="true"){
         debug="false";
    }

    # Pretty JSON mode
    if(pretty=="true"){
        n="\n";
        indent="    ";
    }
    else{
        pretty="false";
    }

}
{
    # First, escape all of the double quotes in the input line, because json.
    gsub(/\"/, "\\\"");

    # Look for a leading [ which indicates an incorrectly constructed log entry
    if($0 ~ /^\[/){
        # This is a logging error.
        if ( send_error=="true" ) {
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
            write_kvp_str("client_ip",$5);

            # The value of the User-Agent request header sent from the client.
            write_kvp_str("user_agent",$6);

            # The session id, if present.
            write_kvp_str("session_id",$7);

            # The user's user id, if a user is logged in.
            write_kvp_str("user_id",$8);

            # The time the the request was received.
            write_kvp_num("start_time",$9);

            # We are not so sure what this number is...
            write_kvp_num("duration",$10);

            # The HTTP verb of the request (GET, POST, etc)
            write_kvp_str("http_verb",$11);

            # The path component of the requested resource.
            write_kvp_str("url_path",$12);

            # The query string, if any, submitted with the request.
            write_kvp_str("query_string",$13);

            # Field 14 is a field that indicates the following fields orginated
            # in the BES, it is not semantically important to NGAP
            # write_kvp_str("bes",$14);

            # The type of BES action/request/command invoked by the request
            write_kvp_str("bes_request",$15);

            # The DAP protocl
            write_kvp_str("dap_version",$16);

            # The local file path to the resource.
            write_kvp_str("local_path",$17);

            # Field 18 is a duplicate of field 13 and if the query string is absent
            # then field 18 will be missing entirely.
            printf(", %s%s\"%sconstraint_expression\": \"%s\"", n, indent, prefix, $18);
            write_kvp_str("constraint_expression",$18);

            print_closer();
        }
        else if(type=="info" && send_info=="true"){
            print_opener();
            write_kvp_str("message",$4);
            print_closer();
        }
        else if(type=="error" && send_error=="true"){
            print_opener();
            write_kvp_str("message",$4);
            print_closer();
        }
        else if(type=="verbose" && send_verbose=="true"){
            print_opener();
            write_kvp_str("message",$4);
            print_closer();
        }
        else if(type == "timing" && send_timing=="true"){

            time_type = $4;

            if(time_type=="start_us"){
                # 1601642669|&|2122|&|timing|&|start_us|&|1601642669945133|&|-|&|TIMER_NAME
                #      1         2      3        4             5             6      7
                print_opener();
                write_kvp_num("start_time",$5);
                write_kvp_str("req_id",$6);
                write_kvp_str("name",$7);
                print_closer();
            }
            else if(time_type=="elapsed_us"){
                # 1601653546|&|7096|&|timing|&|elapsed_us|&|2169|&|start_us|&|1601653546269617|&|stop_us
                #     1          2      3          4          5        6            7                8
                # |&|1601653546271786|&|ReqId|&|TIMER_NAME
                #          9              10       11
                print_opener();
                write_kvp_num("elapsed_time_us",$5);
                write_kvp_num("start_time_us",$7);
                write_kvp_num("stop_time_us",$9);
                write_kvp_str("req_id",$10);
                write_kvp_str("name",$11);
                print_closer();
            }
            else {
                msg = "FAILED to process '"$0"'";
                write_kvp_str("LOG_ERROR",msg);
            }
        }
    }
    else {
        if(debug == "true"){
            print "# Line "NR" is blank, ignored."
        }
    }
}

########################################################################
#
# Opens a json log element with kvp for time, pib and log entry type.
#
function print_opener(){
    printf("{ %s", n);
    printf("%s\"%stime\": %s", indent, prefix, $1);
    write_kvp_num("pid",$2);
    write_kvp_str("type", $3);
}
########################################################################
#
# Closes a json element.
#
function print_closer(){
    printf("%s}\n", n);
}


########################################################################
#
# Retuns the boolean state based on the passed value and the default.
#
function process_bool_value(var_val, dfault, ret_val){
    ret_val = dfault;
    if (length(var_val)>0) {
        if(var_val != "true" && var_val != "1"){
            ret_val="false";
        }
    }
    return ret_val;
}

########################################################################
#
# Writes a key value pair in json. The value is handled as a number
#
function write_kvp_num(key,value){
    printf (", %s%s\"%s%s\": %s", n, indent, prefix, key, value);
}

########################################################################
#
# Writes a key value pair in json. The value handled as a string.
#
function write_kvp_str(key,value){
    printf (", %s%s\"%s%s\": \"%s\"", n, indent, prefix, key, value);
}