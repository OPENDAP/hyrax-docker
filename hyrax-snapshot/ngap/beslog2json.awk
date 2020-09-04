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

    # The time that the log message was written.
    log_fields[1]="time";

    # The PID of the beslistner that wrote the log entry.
    log_fields[2]="pid";

    # Field 3 is a field that indicates the following fields orginated
    # in the OLFS, it is not semantically important to NGAP
    log_fields[3]="olfs";

    log_fields[4]="client_ip";
    log_fields[5]="user_agent";
    log_fields[6]="session_id";
    log_fields[7]="user_id";
    log_fields[8]="start_time";
    log_fields[9]="duration";
    log_fields[10]="http_verb";
    log_fields[11]="url_path";
    log_fields[12]="query_string";

    # Field 13 is a field that indicates the following fields orginated
    # in the BES, it is not semantically important to NGAP
    log_fields[13]="bes";

    log_fields[14]="bes_request";
    log_fields[15]="protocol";
    log_fields[16]="local_path";

    # Field 17 is a duplicate of field 12 and if the query string is absent
    # then field 17 will be missing entirely.
    log_fields[17]="constraint_expression";

    error_fields[1]="time";
    error_fields[2]="pid";
    error_fields[3]="message";

}
{
    if(debug=="true"){
        print "------------------------------------------------"
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
            if(i>1)
                printf(", %s",n);
            printf("%s\"%s\": \"%s\"",indent,error_fields[i],$i);
        }
   }
    printf("%s}\n",n,n);
}
