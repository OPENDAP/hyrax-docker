#
# Translates OPeNDAP bes.logs into JSON
#
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

    # -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    # Log Fields

    # The time that the log message was written.
    log_fields[1]="time";

    # The PID of the beslistener that wrote the log entry.
    log_fields[2]="pid";

    # Field 3 is a field that indicates the following fields originated
    # in the OLFS, it is not semantically important to NGAP
    log_fields[3]="olfs";

    # ip-address of requesting client's system.
    log_fields[4]="client_ip";

    # The value of the User-Agent request header sent from the client.
    log_fields[5]="user_agent";

    # The session id, if present.
    log_fields[6]="session_id";

    # The user's user id, if a user is logged in.
    log_fields[7]="user_id";

    # The time the the request was received.
    log_fields[8]="start_time";

    # We are not so sure what this number is...
    log_fields[9]="duration";

    # The HTTP verb of the request (GET, POST, etc)
    log_fields[10]="http_verb";

    # The path component of the requested resource.
    log_fields[11]="url_path";

    # The query string, if any, submitted with the request.
    log_fields[12]="query_string";

    # Field 13 is a field that indicates the following fields orginated
    # in the BES, it is not semantically important to NGAP
    log_fields[13]="bes";

    # The type of BES action/request/command invoked by the request
    log_fields[14]="bes_request";

    # The DAP protocl
    log_fields[15]="protocol";

    # The local file path to the resource.
    log_fields[16]="local_path";

    # Field 17 is a duplicate of field 12 and if the query string is absent
    # then field 17 will be missing entirely.
    log_fields[17]="constraint_expression";

    # -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    # Error/Message Fields

    # The time that the log message was written.
    error_fields[1]="time";

    # The PID of the beslistener that wrote the log entry.
    error_fields[2]="pid";

    # The message associate with the log entry
    error_fields[3]="message";

}
{
    # First, escape all of the double quotes in the values of the log fields.
    gsub(/\"/, "\\\"");
    
    if(debug=="true"){
        print "------------------------------------------------";
        print $0;
    }

    printf("{%s",n);
    if (NF > 3){
        for(i=1; i<=NF  ; i++){
            if(i!=3 && i!=13 && i!=17){
                if(i>1)
                    printf(", %s",n);
                printf("%s\"%s\": \"%s\"",indent,log_fields[i],$i);
            }
        }
    }
    else {
        for(i=1; i<=NF ; i++){
            if(i>1) {
                printf(", %s",n);
            }
            msg
            printf("%s\"%s\": \"%s\"",indent,error_fields[i],$i);
        }
   }
    printf("%s}\n",n,n);
}
