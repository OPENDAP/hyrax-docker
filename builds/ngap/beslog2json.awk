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
# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
# The behavior of this script can be controlled by setting the values of it's
# "control" variables from the command line invocation.
#
# The control variables are:
#     SEND_REQUESTS (default: "true")
#       SEND_ERRORS (default: "true")
#       SEND_TIMING (default: "false")
#         SEND_INFO (default: "false")
#      SEND_VERBOSE (default: "false")
#            PRETTY (default: "false")
#             DEBUG (default: "false")
#
# You can set the control variables from the awk command line
# using awk's -v option:
#
#   cat /var/log/bes/bes.log | awk -f beslog2json.awk -v SEND_INFO=true -v SEND_TIMING=true
#
# You can have this produce multi-line pretty formatted json output by setting
# the value of "PRETTY" to true:
#    -v PRETTY=true
#
# The variables "N" and "INDENT" are set in the BEGIN section and are 
# determined by the state of the variable "PRETTY" 
# 
# The value of the "PREFIX" variable is hard coded in the BEGIN statement 
# and cannot be set by command line injection.
#
# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

########################################################################
# process_bool_value()
#
# Retuns the boolean state based on the passed value and the default.
#
# Awk doesn't have boolean types so for this work I have it use the
# string values of "true" and "false". If setting the value from the
# command line like:
#    awk -v foo=true -v bar=1
# This function will accept "true" or 1 (and only 1) as a true value.
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
# print_opener()
#
# Opens a json log element with kvp for time, pid and log entry type.
#
# Expects 3 parameters:
#
# unix_time - An integer value of seconds since epoch
# pid - The processes id of the process that created the log entry
# log_type - The type of log entry: request|error|info|timing|verbose
#
function print_opener(unix_time, pid, log_type){
    printf("{ %s", N);
    printf("%s\"%stime\": %s", INDENT, PREFIX, unix_time);
    write_kvp_num("pid", pid);
    write_kvp_str("type", log_type);
}

########################################################################
# print_closer()
#
# Closes a json element.
#
function print_closer(){
    printf("%s}\n", N);
}

########################################################################
# write_kvp_num()
#
# Writes a key value pair in json. The value is handled as a number
#
function write_kvp_num(key,value){
    printf (", %s%s\"%s%s\": %s", N, INDENT, PREFIX, key, value);
}

########################################################################
# write_kvp_str()
#
# Writes a key value pair in json. The value handled as a string.
#
function write_kvp_str(key,value){
    printf (", %s%s\"%s%s\": \"%s\"", N, INDENT, PREFIX, key, value);
}

########################################################################
#
# BEGIN is executed one time, at the beginning of the show.
#
BEGIN {
    # Set the field seperator to the BES log's "|&|" business.
    FS="\\|&\\|";

    # A namespace prefix for our variable names, if desired.
    #PREFIX="hyrax_";
    PREFIX=""

    if(send_all=="true"){
        # Send everything as json.
        SEND_REQUESTS="true"
        SEND_ERRORS="true";
        SEND_TIMING="true";
        SEND_INFO="true";
        SEND_VERBOSE="true";
    }
    else{
        # Transmit request log entries.
        SEND_REQUESTS=process_bool_value(SEND_REQUESTS, "true");

        # Transmit error log messages.
        SEND_ERRORS = process_bool_value(SEND_ERRORS, "true");

        # Transmit timing data.
        SEND_TIMING = process_bool_value(SEND_TIMING, "false");

        # Transmit info log messages..
        SEND_INFO = process_bool_value(SEND_INFO, "false");

        # Transmit verbose  log messages.
        SEND_VERBOSE = process_bool_value(SEND_VERBOSE, "false");
    }

    # Debuggin Mode
    if(DEBUG!="true"){
         DEBUG="false";
    }

    # Pretty JSON mode
    if(PRETTY=="true"){
        N ="\n";
        INDENT="    ";
    }
    else{
        PRETTY="false";
    }

}

#########################################################################
#
# This is essentially the main() of any awk program.
# This {...} block is run on each line in the input file.
#
{
    # First, escape all of the double quotes in the input line, because json.
    gsub(/\"/, "\\\"");

    # Look for a leading "[" which indicates an incorrectly formatted log entry
    if($0 ~ /^\[/){
        # This is a logging error.
        if ( SEND_ERRORS=="true" ) {
            # Make an special error log entry about the error in the log format.
            print_opener(-1, -1, error);
            msg = "OUCH! Input log line "NR" appears to use [ and ] to delimit values. Line: "$0;
            write_kvp_str("message",msg);
            print_closer();
        }
    }
    else if($0.length() != 0) { # Don't process an empty line...

        if(DEBUG=="true"){
            print "------------------------------------------------";
            print $0;
        }
        time=$1;
        pid=$2;
        type=$3;
        if(type=="request" && SEND_REQUESTS=="true"){
            print_opener(time, pid, type);

            # Field $4 always has the value "OLFS". It marks the beginning
            # of things sent by the OLFS. The tag is not needed for ngap logs.
            # write_kvp_str("OLFS",$4);

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

            # Field $14 always has the value "bes" and is used to indicate
            # that the following fields orginated in the BES. It is not
            # semantically important to NGAP
            # write_kvp_str("bes",$14);

            # The type of BES action/request/command invoked by the request
            write_kvp_str("bes_request",$15);

            # The DAP protocl
            write_kvp_str("dap_version",$16);

            # The local file path to the resource.
            write_kvp_str("local_path",$17);

            # Field 18 is a duplicate of field 13 and if the query string is absent
            # then field 18 will be missing entirely.
            write_kvp_str("constraint_expression",$18);

            print_closer();
        }
        else if(type=="info" && SEND_INFO=="true"){
            print_opener(time, pid, type);
            write_kvp_str("message",$4);
            print_closer();
        }
        else if(type=="error" && SEND_ERRORS=="true"){
            print_opener(time, pid, type);
            write_kvp_str("message",$4);
            print_closer();
        }
        else if(type=="verbose" && SEND_VERBOSE=="true"){
            print_opener(time, pid, type);
            write_kvp_str("message",$4);
            print_closer();
        }
        else if(type == "timing" && SEND_TIMING=="true"){

            time_type = $4;

            if(time_type=="start_us"){
                # 1601642669|&|2122|&|timing|&|start_us|&|1601642669945133|&|-|&|TIMER_NAME
                #      1         2      3        4             5             6      7
                print_opener(time, pid, type);
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
                print_opener(time, pid, type);
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
        if(DEBUG == "true"){
            print "# Line "NR" is blank, ignored."
        }
    }
}

