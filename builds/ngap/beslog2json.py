#!/usr/bin/env python3
#
# -*- mode: python; c-basic-offset:4 -*-
#
# This file is part of the Hyrax Docker Project
#
# Copyright (c) 2024 OPeNDAP, Inc.
# Author: Nathan Potter <ndp@opendap.org>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
#
# You can contact OPeNDAP, Inc. at PO Box 112, Saunderstown, RI. 02874-0112.
#
# ----------------------------------------------------------------------------------
# Program beslog2json.py
# Converts BES log lines with the formats described below in to
# a json record.
#
# Log Fields type==request
# 1601646465|&|2122|&|request|&|OLFS|&|0:0:0:0:0:0:0:1|&|USER_AGENT|&|92F3C71F959B56515C98A09088CA2A8E
#    1          2        3       4           5              6               7
# |&|-|&|1601646465304|&|REQUEST-ID|&|HTTP-GET|&|/opendap/hyrax/data/nc/fnoc1.nc.dds|&|u|&|BES
#    8     9             10             11              12                             13   14
# |&|get.dds|&|dap2|&|/Users/ndp/OPeNDAP/hyrax/build/share/hyrax/data/nc/fnoc1.nc|&|u
#      15       16                              17                                  18
#
# 1601642679|&|2122|&|request|&|RequestFields
# 1601642669|&|2122|&|timing|&|TimingFields
# 1601642669|&|2122|&|verbose|&|MessageField
# 1601642679|&|2122|&|info|&|MessageField
# 1601642679|&|2122|&|error|&|MessageField
#
import sys
import json
import getopt
import time
import os


the_prefix=""
##########################################################
# Global variable for debuggin control.
debug_flag = False

##########################################################
# The usual delimiter suspects
bes_log_field_delimiter = "|&|"
bes_square_bracket_log_delimiter = "]["

##########################################################
# Default configuration for what gets written out as JSON
# These may be overridden by command line options.
TRANSMIT_REQUEST_LOG = True
TRANSMIT_INFO_LOG    = True
TRANSMIT_ERROR_LOG   = True
TRANSMIT_VERBOSE_LOG = True
TRANSMIT_TIMING_LOG  = False

##########################################################
# JSON Shared Log Record Keys (may receive a user supplied prefix)
# We make variables for these because they may get modified
# by a user injected prefix.
TIME_KEY    = "time"
PID_KEY     = "pid"
TYPE_KEY    = "type"
MESSAGE_KEY = "message"
def add_prefix_to_shared_log_keys():
    """Applies user supplied prefix to shared log record keys """
    global TIME_KEY
    global PID_KEY
    global TYPE_KEY
    global MESSAGE_KEY

    if len(the_prefix) != 0 :
        TIME_KEY = the_prefix + TIME_KEY
        PID_KEY = the_prefix + PID_KEY
        TYPE_KEY = the_prefix + TYPE_KEY
        MESSAGE_KEY = the_prefix + MESSAGE_KEY


##########################################################
# Timing Log Keys
# Log Fields type=="timing"
# We make variables for these because they may get modified
# by a user injected prefix.
ELAPSED_TIME_KEY     = "elapsed-us"
START_TIME_KEY       = "start-us"
STOP_TIME_KEY        = "stop-us"
REQUEST_ID_TIMER_KEY = "request-id"
TIMER_NAME_KEY       = "timer-name"
def add_prefix_to_timing_log_keys():
    """Applies user supplied prefix to timing log record keys """
    global ELAPSED_TIME_KEY
    global START_TIME_KEY
    global STOP_TIME_KEY
    global REQUEST_ID_TIMER_KEY
    global TIMER_NAME_KEY

    if len(the_prefix) != 0 :
        ELAPSED_TIME_KEY = the_prefix + ELAPSED_TIME_KEY
        START_TIME_KEY = the_prefix + START_TIME_KEY
        STOP_TIME_KEY = the_prefix + STOP_TIME_KEY
        REQUEST_ID_TIMER_KEY = the_prefix + REQUEST_ID_TIMER_KEY
        TIMER_NAME_KEY = the_prefix + TIMER_NAME_KEY

######################################################################################################
# Request Log Keys  (may receive a user supplied prefix)
# Log Fields type=="request"
# We make variables for these because they may get modified by a user injected prefix.
CLIENT_IP_KEY       = "client-ip"
USER_AGENT_KEY      = "user-agent"
SESSION_ID_KEY      = "session-id"
USER_ID_KEY         = "user-id"
OLFS_START_TIME_KEY = "olfs-start-time"
REQUEST_ID_KEY      = "requiest-id"
HTTP_VERB_KEY       = "http-verb"
URL_PATH_KEY        = "url-path"
QUERY_STRING_KEY    = "query-string"
BES_ACTION_KEY      = "bes-action"
RETURN_AS_KEY       = "return-as"
LOCAL_PATH_KEY      = "local-path"
CE_KEY              = "ce"
def add_prefix_to_request_log_keys():
    """Applies user supplied prefix to request log record keys """
    global CLIENT_IP_KEY
    global USER_AGENT_KEY
    global SESSION_ID_KEY
    global USER_ID_KEY
    global OLFS_START_TIME_KEY
    global REQUEST_ID_KEY
    global HTTP_VERB_KEY
    global URL_PATH_KEY
    global QUERY_STRING_KEY
    global BES_ACTION_KEY
    global RETURN_AS_KEY
    global LOCAL_PATH_KEY
    global CE_KEY

    if len(the_prefix) != 0 :
        CLIENT_IP_KEY = the_prefix + CLIENT_IP_KEY
        USER_AGENT_KEY = the_prefix + USER_AGENT_KEY
        SESSION_ID_KEY = the_prefix + SESSION_ID_KEY
        USER_ID_KEY = the_prefix + USER_ID_KEY
        OLFS_START_TIME_KEY = the_prefix + OLFS_START_TIME_KEY
        REQUEST_ID_KEY = the_prefix + REQUEST_ID_KEY
        HTTP_VERB_KEY = the_prefix + HTTP_VERB_KEY
        URL_PATH_KEY = the_prefix + URL_PATH_KEY
        QUERY_STRING_KEY = the_prefix + QUERY_STRING_KEY
        BES_ACTION_KEY = the_prefix + BES_ACTION_KEY
        RETURN_AS_KEY = the_prefix + RETURN_AS_KEY
        LOCAL_PATH_KEY = the_prefix + LOCAL_PATH_KEY
        CE_KEY = the_prefix + CE_KEY


##########################################################
def debug(msg):
    """
        Writes msg to stderr when the debug_flag is enabled

        Args:
            msg: The message to write to stderr
    """
    if debug_flag:
        print("#", msg.replace("\n","\\n"), file=sys.stderr)
        sys.stderr.flush()

##########################################################
def eord(bool_val):
    """
    Converts a boolean to the strings 'enabled' or 'disabled' according to the value the boolean

    Args:
        bool_val: The boolean values to convert to 'enabled' or 'disabled'

    Returns:
        The string 'enabled' or 'disabled' depending on the value of bool_val
    """
    if bool_val:
        return "enabled"
    else:
        return "disabled"

##########################################################
def show_config():
    """Transmits the configuration state to stderr when in debug mode is enabled"""
    if debug_flag:
        debug(f"debug_flag is {str(debug_flag).lower()}")
        debug(f"TRANSMIT_REQUEST_LOG is {eord(TRANSMIT_REQUEST_LOG)}")
        debug(f"TRANSMIT_INFO_LOG is {eord(TRANSMIT_INFO_LOG)}")
        debug(f"TRANSMIT_ERROR_LOG is {eord(TRANSMIT_ERROR_LOG)}")
        debug(f"TRANSMIT_VERBOSE_LOG is {eord(TRANSMIT_VERBOSE_LOG)}")
        debug(f"TRANSMIT_TIMING_LOG is {eord(TRANSMIT_TIMING_LOG)}")

##########################################################
def request_log_to_json(log_fields, json_log_record):
    """
    Ingests a BES request log record

    Request Log Codex  (may receive a user supplied prefix)
    Log Fields type==request
    1601646465|&|2122|&|request|&|OLFS|&|0:0:0:0:0:0:0:1|&|USER_AGENT|&|92F3C71F959B56515C98A09088CA2A8E
       0          1        2       3           4              5               6
    |&|-|&|1601646465304|&|REQUEST-ID|&|HTTP-GET|&|/opendap/hyrax/data/nc/fnoc1.nc.dds|&|u|&|BES
       7     8              9             10              11                             12   13
    |&|get.dds|&|dap2|&|/Users/ndp/OPeNDAP/hyrax/build/share/hyrax/data/nc/fnoc1.nc|&|u
         14       15                              16                                  17

    Request Log Record
    
    Field#: key-name
    ------:--------------------
         0: start-time
         1: pid
         2: type of log record
         3: olfs boundary tag (ignored)
         4: client-ip
         5: user-agent
         6: session-id
         7: user-id
         8: olfs-start-time
         9: request-id
        10: http-verb
        11: url-path
        12: query-string
        13: bes boundary key (ignored)
        14: bes-action
        15: return-as
        16: local-path
        17: ce

    Args:
        log_fields: The BES log line, parsed into fields, to process
        json_log_record: The dictionary to populate with the json log fields.

    Returns:
        A boolean indicating if the json result should be transmitted.
    """
    debug("Processing REQUEST_MESSAGE_TYPE")
    send_it = False
    if TRANSMIT_REQUEST_LOG:
        json_log_record[CLIENT_IP_KEY] = log_fields[4]
        json_log_record[USER_AGENT_KEY] = log_fields[5]
        json_log_record[SESSION_ID_KEY] = log_fields[6]
        json_log_record[USER_ID_KEY] = log_fields[7]
        json_log_record[OLFS_START_TIME_KEY] = log_fields[8]
        json_log_record[REQUEST_ID_KEY] = log_fields[9]
        json_log_record[HTTP_VERB_KEY] = log_fields[10]
        json_log_record[URL_PATH_KEY] = log_fields[11]
        json_log_record[QUERY_STRING_KEY] = log_fields[12]
        json_log_record[BES_ACTION_KEY] = log_fields[14]
        json_log_record[RETURN_AS_KEY] = log_fields[15]
        json_log_record[LOCAL_PATH_KEY] = log_fields[16]
        if len(log_fields) > 17:
            json_log_record[CE_KEY] = log_fields[17]
        else:
            json_log_record[CE_KEY] = "-"

        send_it = True
    else:
        debug(f"TRANSMIT_REQUEST_LOG: {eord(TRANSMIT_REQUEST_LOG)}")

    return send_it


##########################################################
def info_log_to_json(log_fields, json_log_record):
    """
    Ingests a BES info log record

    Args:
        log_fields: The BES log line, parsed into fields, to process
        json_log_record: The dictionary to populate with the json log fields.

    Returns:
        A boolean indicating if the json result should be transmitted.
    """
    debug("Processing INFO_MESSAGE_TYPE")
    send_it = False
    if TRANSMIT_INFO_LOG:
        json_log_record[MESSAGE_KEY] = log_fields[3]
        send_it = True
    else:
        debug(f"TRANSMIT_INFO_LOG: {eord(TRANSMIT_INFO_LOG)}")

    return send_it


##########################################################
def error_log_to_json(log_fields, json_log_record):
    """
    Ingests a BES error log record

    Args:
        log_fields: The BES log line, parsed into fields, to process
        json_log_record: The dictionary to populate with the json log fields.

    Returns:
        A boolean indicating if the json result should be transmitted.
    """
    debug("Processing ERROR_MESSAGE_TYPE")
    send_it = False
    if TRANSMIT_ERROR_LOG:
        json_log_record[MESSAGE_KEY] = log_fields[3]
        send_it = True
    else:
        debug(f"TRANSMIT_ERROR_LOG: {eord(TRANSMIT_ERROR_LOG)}")

    return send_it


##########################################################
def verbose_log_to_json(log_fields, json_log_record):
    """
    Ingests a BES verbose log record

    Args:
    log_fields: The BES log line, parsed into fields, to process
    json_log_record: The dictionary to populate with the json log fields.

    Returns:
    A boolean indicating if the json result should be transmitted.
    """
    debug("Processing VERBOSE_MESSAGE_TYPE")
    send_it = False
    if TRANSMIT_VERBOSE_LOG:
        json_log_record[MESSAGE_KEY] = log_fields[3]
        send_it = True
    else:
        debug(f"TRANSMIT_VERBOSE_LOG: {eord(TRANSMIT_VERBOSE_LOG)}")

    return send_it


##########################################################
def timing_log_to_json(log_fields, json_log_record):
    """
    Ingests a BES timing log record

    Args:
    log_fields: The BES log line, parsed into fields, to process
    json_log_record: The dictionary to populate with the json log fields.

    Returns:
    A boolean indicating if the json result should be transmitted.
    """
    debug("Processing TIMING_MESSAGE_TYPE")
    send_it = False
    if TRANSMIT_TIMING_LOG:
        if log_fields[3] == ELAPSED_TIME_KEY :
            json_log_record[ELAPSED_TIME_KEY] = int(log_fields[4])
            json_log_record[START_TIME_KEY] = int(log_fields[6])
            json_log_record[STOP_TIME_KEY] = int(log_fields[8])
            json_log_record[REQUEST_ID_TIMER_KEY] = log_fields[9]
            json_log_record[TIMER_NAME_KEY] = log_fields[10]
            send_it = True
    else:
        debug(f"TRANSMIT_TIMING_LOG is {eord(TRANSMIT_TIMING_LOG)}")

    return send_it
# - - - - - - - - - - - - - - - - - - - - - - - - - - - -

##########################################################
def processing_error(msg, json_log_record):
    """
    Populate response dictionary with a log_line processing error.

    Args:
        msg: The error message string
        json_log_record: The JSON log record dictionary

     Returns:
        A boolean indicating if the json result should be transmitted.
   """
    # Use the current Unix time
    json_log_record[TIME_KEY] = int(time.time())
    # Use the PID of this beslog2json process.
    json_log_record[PID_KEY]  = os.getpid()
    json_log_record[TYPE_KEY] = "error"
    json_log_record[MESSAGE_KEY] = msg
    return True


##########################################################
def square_bracket_timing_record(log_fields, json_log_record):
    """
    Process a BES timing log record that has [] delimiters.

    Timing log entry example and forensics:
    log: [UTC Wed Nov 27 18:48:20 2024][pid:117][thread:139661163814208][timing][ELAPSED][4 us][STARTED][1732733300645844 us][STOPPED][1732733300645848 us][-][Command timing: BESXMLInterface::transmit_data() - ]
     0 - [UTC Wed Nov 27 18:48:20 2024]
     1 - [pid:117]
     2 - [thread:139661163814208]
     3 - [timing]
     4 - [ELAPSED]
     5 - [4 us]
     6 - [STARTED]
     7 - [1732733300645844 us]
     8 - [STOPPED]
     9 - [1732733300645848 us]
    10 - [-]
    11 - [Command timing: BESXMLInterface::transmit_data() - ]

    Args:
        log_fields: The BES log line (with [] delimiters) parsed into fields
        json_log_record: The dictionary to populate with the json log fields.

    Returns:
        A boolean indicating if the json result should be transmitted.
    """
    prolog ="square_bracket_timing_record()"
    debug(f"{prolog} BEGIN")
    send_it = False
    if TRANSMIT_TIMING_LOG:
        debug(f"{prolog} Processing timing log line")
        if log_fields[4] == "ELAPSED":
            debug(f"{prolog} Found ELAPSED ")
            elapsed_us = log_fields[5][:-3]
            debug(f"{prolog} elapsed_us: {elapsed_us} ")
            json_log_record[ELAPSED_TIME_KEY] = int(elapsed_us)

            start_us = log_fields[7][:-3]
            debug(f"{prolog} start_us: {start_us} ")
            json_log_record[START_TIME_KEY] = int(start_us)

            stop_us = log_fields[9][:-3]
            debug(f"{prolog} stop_us: {stop_us} ")
            json_log_record[STOP_TIME_KEY] = int(stop_us)

            json_log_record[REQUEST_ID_TIMER_KEY] = log_fields[10]
            json_log_record[TIMER_NAME_KEY] = log_fields[11]
            send_it = True
            debug(f"{prolog} json: {json.dumps(json_log_record)} ")
        else:
            return processing_error(f"{prolog} Failed to identify timing data in log_fields: {log_fields}", json_log_record)
    else:
        debug(f"TRANSMIT_TIMING_LOG: {eord(TRANSMIT_TIMING_LOG)}")

    return send_it


##########################################################
# @TODO Not a full implementation, just timing logs for now.
def square_bracket_log_record(log_line, json_log_record):
    """
    Process a BES log line that has [] delimiters.

    Args:
        log_line: The BES log line (with [] delimiters) to process
        json_log_record: The dictionary to populate with the json log fields.

    Returns:
        A boolean indicating if the json result should be transmitted.
    """
    prolog ="square_bracket_log_record()"
    log_fields = log_line.split(bes_square_bracket_log_delimiter)

    # Remove the leading open square bracket character from the time string.
    time_str = log_fields[0]
    if time_str.startswith("["):
        time_str = time_str[1:]
    json_log_record[TIME_KEY] = time_str

    pid = log_fields[1][4:]
    json_log_record[PID_KEY]  = int(pid)

    # This value is not used...
    # thread = log_fields[2][7:]
    log_record_type = log_fields[3]
    json_log_record[TYPE_KEY] = log_record_type

    debug(json.dumps(json_log_record))
    if log_record_type == "timing":
        send_it = square_bracket_timing_record(log_fields, json_log_record)
    else:
        # @TODO Not a full implementation, just timing logs for now.
        send_it = processing_error(f"{prolog} Unable to process log_line: \"{log_line}\" Only timing "
                                   f"message are supported for square bracket delimited logs;", json_log_record)

    return send_it



##########################################################
def beslog2json(line_count, log_line):
    """
    Converts a BES log record into a kvp json representation.

    After the BES log line is processed the json result is written to stdout.
    """
    #line_count=0
    #show_config()
    json_log_record={}
    prolog ="beslog2json()"

    if log_line.startswith("["):
        send_it = square_bracket_log_record(log_line, json_log_record)
    else:
        log_fields = log_line.split(bes_log_field_delimiter)
        debug(f"log_fields length: {len(log_fields)}")

        if len(log_fields) > 3:
                time_str = log_fields[0]
                if time_str.isnumeric():
                    json_log_record[TIME_KEY] = int(log_fields[0])
                else:
                    json_log_record[TIME_KEY] = log_fields[0]

                json_log_record[PID_KEY]  = int(log_fields[1])
                log_record_type = log_fields[2]
                json_log_record[TYPE_KEY] = log_record_type

                if log_record_type == "request":
                    send_it = request_log_to_json(log_fields, json_log_record)

                elif log_record_type == "info":
                    send_it = info_log_to_json(log_fields, json_log_record)

                elif log_record_type == "error":
                    send_it = error_log_to_json(log_fields, json_log_record)

                elif log_record_type == "verbose":
                    send_it = verbose_log_to_json(log_fields, json_log_record)

                elif log_record_type == "timing":
                    send_it = timing_log_to_json(log_fields, json_log_record)

                else:
                    msg = f"{prolog} UNKNOWN LOG RECORD TYPE {log_record_type} log_line: {log_line}"
                    debug(msg)
                    send_it = processing_error(msg, json_log_record)

        else:
            msg = f"{prolog} OUCH! Incompatible input log line {line_count}  log_line: {log_line}"
            debug(msg)
            send_it = processing_error(msg, json_log_record)

    if send_it:
        print(json.dumps(json_log_record))

##########################################################
def read_from_stdin():
    """
    Reads BES log lines from stdin and turns them into JSON records on stdout.
    Reads lines until EOF is encountered.
    """
    prolog="read_from_stdin()"

    line_count=0
    show_config()
    while True:
        line_count += 1
        debug("-------------------------------------------------------------------------")
        debug(f"line: {line_count}")
        try:
            log_line = input()
            debug(f"log_line:  {log_line}")
        except EOFError:
            debug("End of input reached. Exiting...")
            break

        if not log_line:
            debug("Unable to read from input(). Exiting...")
            break

        debug(f"Log Line({str(line_count)}): {log_line}")
        try:
            beslog2json(line_count, log_line)
        except Exception as e:
            msg = (f"{prolog} OUCH! Incompatible input log line {line_count} failed with the "
                   f"message: \"{str(e)}\" log_line: {log_line}")
            debug(msg)
            json_log_record={}
            processing_error(msg, json_log_record)
            print(json.dumps(json_log_record))



##########################################################
def read_from_file(filename):
    """
    Reads BES log lines from a file and turns them into JSON records on stdout.

    Args:
        filename: The name of the file containing the BES log records with the |&| seperator.
    """
    prolog="read_from_file()"
    with open(filename, 'r') as log_file:
        line_count=0
        show_config()
        for log_line in log_file:
            line_count += 1
            debug("-------------------------------------------------------------------------")
            debug(f"line: {line_count}")
            debug(f"log_line: {log_line}")

            if not log_line:
                debug(f"Failed to read line from file: {filename} line_count: {line_count} Exiting...")
                break

            try:
                beslog2json(line_count, log_line)
            except Exception as e:
                msg = (f"{prolog} OUCH! Incompatible input log line {line_count} failed with the "
                       f"message: \"{str(e)}\" log_line: {log_line}")
                debug(msg)
                json_log_record={}
                processing_error(msg, json_log_record)
                print(json.dumps(json_log_record))

##########################################################
def usage():
    """Print usage statement to stderr"""
    the_words = """
beslog2json.py

NAME
    beslog2json.py - Convert BES log lines to valid json formatted kvp.

SYNOPSIS
    beslog2json.py [-d][-r value][-i value][-e value][-v value][-t value][-p value][-f value]

DESCRIPTION
    Reads BES log lines from stdin (default) or from a file 
    (using -f). Writes a json result to stdout. Using stdin 
    allows one to run a shell process that transmit the bes 
    log to this program, endlessly.
    
        tail -f /var/log/bes/bes.log | python3 beslog2json.py 
        
    You can control what appears in json output, as well as 
    specify a file to read and a debugging option as follows:

        -r value, --request value
            Passing value that begins with an 'f' or 'F' will 
            evaluate to False. All else evaluates to True.

        -i value, --info value
            Passing value that begins with an 'f' or 'F' will e
            valuate to False. All else evaluates to True.

        -e value, --error value
            Passing value that begins with an 'f' or 'F' will 
            evaluate to False. All else evaluates to True.

        -v value, --verbose value
            Passing value that begins with an 'f' or 'F' will 
            evaluate to False. All else evaluates to True.

        -t value, --timing value
            Passing value that begins with an 'f' or 'F' will 
            evaluate to False. All else evaluates to True.

        -p value, --prefix value
            A (short) string that will be prepended to the 
            name of every field in the json log record with a 
            separating '-' character. The prefix string should 
            be alpha/numeric with no special characters. For 
            example none of:  ",][}{.-_ !?><$#^+ and similar.
            
        -f value, --filename value
            The path/filename of the BES log file to use as 
            input. (primarily for testing)

        -d, --debug
            Turns on debugging output which is transmitted on stderr.

EXAMPLE
    tail -f bes.log | python3 beslog2json.py -t true -p besd 
    
beslog2json.py
"""
    print(the_words, file=sys.stderr)

##########################################################
##########################################################
##########################################################


##########################################################
# main
#
def main(argv):
    global debug_flag
    global TRANSMIT_REQUEST_LOG
    global TRANSMIT_INFO_LOG
    global TRANSMIT_ERROR_LOG
    global TRANSMIT_VERBOSE_LOG
    global TRANSMIT_TIMING_LOG
    global the_prefix

    input_filename=""

    try:
        opts, args = getopt.getopt(argv, "hdr:i:e:v:t:p:f:", ["help", "debug", "requests=", "info=", "error=", "verbose=", "timing=", "prefix=", "filename="])
    except getopt.GetoptError:
        usage()
        sys.exit(2)

    for opt, arg in opts:
        if opt in ("-h", "--help"):
            usage()
            sys.exit()

        elif opt in ("-r", "--requests"):
            TRANSMIT_REQUEST_LOG = not arg.lower().startswith("f")

        elif opt in ("-i", "--info"):
            TRANSMIT_INFO_LOG    = not arg.lower().startswith("f")

        elif opt in ("-e", "--error"):
            TRANSMIT_ERROR_LOG   = not arg.lower().startswith("f")

        elif opt in ("-v", "--verbose"):
            TRANSMIT_VERBOSE_LOG = not arg.lower().startswith("f")

        elif opt in ("-t", "--timing"):
            TRANSMIT_TIMING_LOG  = not arg.lower().startswith("f")

        elif opt in ("-p", "--prefix"):
            the_prefix  = arg + "-"
            add_prefix_to_shared_log_keys()
            add_prefix_to_request_log_keys()
            add_prefix_to_timing_log_keys()

        elif opt in ("-d", "--debug"):
            debug_flag = True

        elif opt in ("-f", "--filename"):
            input_filename = arg


    if len(input_filename) > 0:
        read_from_file(input_filename)
    else:
        read_from_stdin()


if __name__ == "__main__":
    main(sys.argv[1:])

