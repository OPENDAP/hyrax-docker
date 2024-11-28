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
import re
import json
import getopt
import ast
import time
import os


##########################################################
# Global variable for debuggin control.
debug_flag = False

##########################################################
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
# Keys Common To All Log Formats
TIME_KEY="time"
PID_KEY="pid"
TYPE_KEY="type"

##########################################################
# Log Message Type Keys
REQUEST_MESSAGE_TYPE="request"
INFO_MESSAGE_TYPE="info"
ERROR_MESSAGE_TYPE="error"
VERBOSE_MESSAGE_TYPE="verbose"
TIMING_MESSAGE_TYPE="timing"

##########################################################
# Timing Log Keys
MESSAGE_KEY="message"
ELAPSED_TIME_KEY="elapsed_us"
START_TIME_KEY="start_us"
STOP_TIME_KEY="stop_us"
REQUEST_ID_TIMER_KEY="request_id"
TIMER_NAME_KEY="timer_name"

######################################################################################################
# Request Log Keys
# Log Fields type==request
# 1601646465|&|2122|&|request|&|OLFS|&|0:0:0:0:0:0:0:1|&|USER_AGENT|&|92F3C71F959B56515C98A09088CA2A8E
#    0          1        2       3           4              5               6
# |&|-|&|1601646465304|&|REQUEST-ID|&|HTTP-GET|&|/opendap/hyrax/data/nc/fnoc1.nc.dds|&|u|&|BES
#    7     8              9             10              11                             12   13
# |&|get.dds|&|dap2|&|/Users/ndp/OPeNDAP/hyrax/build/share/hyrax/data/nc/fnoc1.nc|&|u
#      14       15                              16                                  17
#
#  0: start_time
#  1: pid
#  2: request type
#  3: olfs boundary tag (ignored)
#  4: client_ip
#  5: user_agent
#  6: session_id
#  7: user_id
#  8: olfs_start_time
#  9: request_id
# 10: http_verb
# 11: url_path
# 12: query_string
# 13: bes boundary key (ignored)
# 14: bes action
# 15: return as
# 16: local_path
# 17: ce

CLIENT_IP_KEY="client-ip" # field 4
USER_AGENT_KEY="user-agent" # field 5
SESSION_ID_KEY="session-id" # field 6
USER_ID_KEY="user-id" # field 7
OLFS_START_TIME_KEY="olfs-start-time" # field 8
REQUEST_ID_KEY="requiest-id" # field 9
HTTP_VERB_KEY="http-verb" # field 10
URL_PATH_KEY="url-path" # field 11
QUERY_STRING_KEY="query-string" # field 12
BES_ACTION_KEY="bes-action" # field 14
RETURN_AS_KEY="return-as" # field 15
LOCAL_PATH_KEY="local-path" # field 16
CE_KEY="constraint-expression" # field 17

##########################################################
def debug(msg):
    """Writes msg to stderr when the debug_flag is enabled"""
    if debug_flag:
        print("#", msg, file=sys.stderr)
        sys.stderr.flush()


##########################################################
def torf(bool_val):
    """Returns 'true' or 'false' according to the value of bool_val"""
    if bool_val:
        return "true"
    else:
        return "false"

##########################################################
def eord(bool_val):
    """Returns 'enabled' or 'disabled' according to the value of bool_val"""
    if bool_val:
        return "enabled"
    else:
        return "disabled"

##########################################################
def show_config():
    """Shows the configuration state when in debuggin mode"""
    debug(f"debug_flag is  {torf(debug_flag)}")
    debug(f"TRANSMIT_REQUEST_LOG is {eord(TRANSMIT_REQUEST_LOG)}")
    debug(f"TRANSMIT_INFO_LOG is {eord(TRANSMIT_INFO_LOG)}")
    debug(f"TRANSMIT_ERROR_LOG is {eord(TRANSMIT_ERROR_LOG)}")
    debug(f"TRANSMIT_VERBOSE_LOG is {eord(TRANSMIT_VERBOSE_LOG)}")
    debug(f"TRANSMIT_TIMING_LOG is {eord(TRANSMIT_TIMING_LOG)}")

##########################################################
def request_log_to_json(log_fields, json_log_line):
    """Ingests a BES request log record"""
    debug("Processing REQUEST_MESSAGE_TYPE")

    send_it = False
    if TRANSMIT_REQUEST_LOG:
        json_log_line[CLIENT_IP_KEY] = log_fields[4]
        json_log_line[USER_AGENT_KEY] = log_fields[5]
        json_log_line[SESSION_ID_KEY] = log_fields[6]
        json_log_line[USER_ID_KEY] = log_fields[7]
        json_log_line[OLFS_START_TIME_KEY] = log_fields[8]
        json_log_line[REQUEST_ID_KEY] = log_fields[9]
        json_log_line[HTTP_VERB_KEY] = log_fields[10]
        json_log_line[URL_PATH_KEY] = log_fields[11]
        json_log_line[QUERY_STRING_KEY] = log_fields[12]
        json_log_line[BES_ACTION_KEY] = log_fields[14]
        json_log_line[RETURN_AS_KEY] = log_fields[15]
        json_log_line[LOCAL_PATH_KEY] = log_fields[16]

        if len(log_fields) > 17:
            json_log_line[CE_KEY] = log_fields[17]
        else:
            json_log_line[CE_KEY] = "-"
        send_it = True
    else:
        debug(f"TRANSMIT_REQUEST_LOG: {eord(TRANSMIT_REQUEST_LOG)}")

    return send_it


##########################################################
def info_log_to_json(log_fields, json_log_line):
    """Ingests a BES info log record"""
    debug("Processing INFO_MESSAGE_TYPE")
    send_it = False
    if TRANSMIT_INFO_LOG:
        json_log_line[MESSAGE_KEY] = log_fields[3]
        send_it = True
    else:
        debug(f"TRANSMIT_INFO_LOG: {eord(TRANSMIT_INFO_LOG)}")

    return send_it


##########################################################
def error_log_to_json(log_fields, json_log_line):
    """Ingests a BES error log record"""
    debug("Processing ERROR_MESSAGE_TYPE")

    send_it = False
    if TRANSMIT_ERROR_LOG:
        json_log_line[MESSAGE_KEY] = log_fields[3]
        send_it = True
    else:
        debug(f"TRANSMIT_ERROR_LOG: {eord(TRANSMIT_ERROR_LOG)}")

    return send_it


##########################################################
def verbose_log_to_json(log_fields, json_log_line):
    """Ingests a BES verbose log record"""
    debug("Processing VERBOSE_MESSAGE_TYPE")

    send_it = False
    if TRANSMIT_VERBOSE_LOG:
        json_log_line[MESSAGE_KEY] = log_fields[3]
        send_it = True
    else:
        debug(f"TRANSMIT_VERBOSE_LOG: {eord(TRANSMIT_VERBOSE_LOG)}")

    return send_it


##########################################################
def timing_log_to_json(log_fields, json_log_line):
    """Ingests a BES timing log record"""
    debug("Processing TIMING_MESSAGE_TYPE")
    send_it = False
    if TRANSMIT_TIMING_LOG:
        if log_fields[3] == ELAPSED_TIME_KEY :
            json_log_line[ELAPSED_TIME_KEY] = int(log_fields[4])
            json_log_line[START_TIME_KEY] = int(log_fields[6])
            json_log_line[STOP_TIME_KEY] = int(log_fields[8])
            json_log_line[REQUEST_ID_TIMER_KEY] = log_fields[9]
            json_log_line[TIMER_NAME_KEY] = log_fields[10]
            send_it = True
    else:
        debug(f"TRANSMIT_TIMING_LOG is {eord(TRANSMIT_TIMING_LOG)}")

    return send_it
# - - - - - - - - - - - - - - - - - - - - - - - - - - - -

##########################################################
def processing_error(msg, json_log_line):
    """Populate response dictionary with a processing error message"""
    # Use the current Unix time
    json_log_line[TIME_KEY] = int(time.time())

    # Use the PID of this beslog2json process.
    json_log_line[PID_KEY]  = os.getpid()

    json_log_line[TYPE_KEY] = ERROR_MESSAGE_TYPE
    json_log_line[MESSAGE_KEY] = msg
    return True


##########################################################
def square_bracket_timing_record(log_fields, json_log_line):
    """
    Process a BES log line that has [] delimiters.
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
            json_log_line[ELAPSED_TIME_KEY] = int(elapsed_us)

            start_us = log_fields[7][:-3]
            debug(f"{prolog} start_us: {start_us} ")
            json_log_line[START_TIME_KEY] = int(start_us)

            stop_us = log_fields[9][:-3]
            debug(f"{prolog} stop_us: {stop_us} ")
            json_log_line[STOP_TIME_KEY] = int(stop_us)

            json_log_line[REQUEST_ID_TIMER_KEY] = log_fields[10]
            json_log_line[TIMER_NAME_KEY] = log_fields[11]
            send_it = True
            debug(f"{prolog} json: {json.dumps(json_log_line)} ")
            debug(f"{prolog} send_it: {send_it} ")
        else:
            return processing_error(f"{prolog} Failed to identify timing data in log_line: {log_line}", json_log_line)
    else:
        debug(f"TRANSMIT_TIMING_LOG: {eord(TRANSMIT_TIMING_LOG)}")

    return send_it


##########################################################
# @TODO Not a full implementation, just timing logs for now.
def square_bracket_log_line(log_line, json_log_line):
    """Process a BES log line that has [] delimiters."""
    send_it = False
    log_fields = log_line.split(bes_square_bracket_log_delimiter)

    # Remove the leadin "["  from the time string.
    time_str = log_fields[0]
    if time_str.startswith("["):
        time_str = time_str[1:]
    json_log_line[TIME_KEY] = time_str

    pid = log_fields[1][4:]
    json_log_line[PID_KEY]  = int(pid)

    # This value is not used...
    # thread = log_fields[2][7:]

    type = log_fields[3]
    json_log_line[TYPE_KEY]  = type

    debug(json.dumps(json_log_line))
    if type == TIMING_MESSAGE_TYPE:
        send_it = square_bracket_timing_record(log_fields, json_log_line)
    else:
        send_it = processing_error(f"Incompatible log_line: {log_line}", json_log_line)

    return send_it


##########################################################
def beslog2json():
    """
    Converts BES log content into a kvp json representation.processing_error
    - Input is only read from stdin and output is written to stdout.
    - Reads lines until EOF is encountered.
    """
    line_count=0
    show_config()
    while True:
        line_count += 1
        json_log_line={}
        log_line=""
        send_it = False

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

        if log_line.startswith("["):
            send_it = square_bracket_log_line(log_line, json_log_line)
        else:
            debug(f"Log Line({str(line_count)}): {log_line}")
            log_fields = log_line.split(bes_log_field_delimiter)
            debug(f"log_fields length: {len(log_fields)}")

            if len(log_fields) > 3:
                try:
                    time_str = log_fields[0]
                    if time_str.isnumeric():
                        json_log_line[TIME_KEY] = int(log_fields[0])
                    else:
                        json_log_line[TIME_KEY] = log_fields[0]

                    json_log_line[PID_KEY]  = int(log_fields[1])
                    log_record_type = log_fields[2]
                    json_log_line[TYPE_KEY] = log_record_type

                    if log_record_type == REQUEST_MESSAGE_TYPE:
                        send_it = request_log_to_json(log_fields, json_log_line)

                    elif log_record_type == INFO_MESSAGE_TYPE:
                        send_it = info_log_to_json(log_fields, json_log_line)

                    elif log_record_type == ERROR_MESSAGE_TYPE:
                        send_it = error_log_to_json(log_fields, json_log_line)

                    elif log_record_type == VERBOSE_MESSAGE_TYPE:
                        send_it = verbose_log_to_json(log_fields, json_log_line)

                    elif log_record_type == TIMING_MESSAGE_TYPE:
                        send_it = timing_log_to_json(log_fields, json_log_line)

                    else:
                        msg = f"UNKNOWN LOG RECORD TYPE {log_record_type} log_line: {log_line}"
                        debug(msg)
                        send_it = processing_error(msg)

                except Exception as e:
                    msg = (f"OUCH! Incompatible input log line {line_count} failed with the "
                    f"message: \"{str(e)}\" log_line: {log_line}")
                    debug(msg)
                    send_it = processing_error(msg, json_log_line)

            else:
                msg = f"OUCH! Incompatible input log line {line_count}  log_line: {log_line}"
                debug(msg)
                send_it = processing_error(msg, json_log_line)

        if send_it:
            print(json.dumps(json_log_line))


##########################################################
def usage():
    """Print usage statement to stderr"""
    the_words = """
beslog2json.py

NAME
    beslog2json.py - Convert BES log lines to valid json formatted kvp.

SYNOPSIS
    tail -f bes.log | python3 beslog2json.py [-d] [-r value] [-i value] [-e value] [-v value] [-t value]

DESCRIPTION
    Reads bes log lines from stdin and writes their JSON kvp to stdout.
    You can control the json output as follows:

       -r value, --request value
           Passing value that begins with an 'f' or 'F' will evaluate to False. All else evaluates to True.

       -i value, --info value
           Passing value that begins with an 'f' or 'F' will evaluate to False. All else evaluates to True.

       -e value, --error value
           Passing value that begins with an 'f' or 'F' will evaluate to False. All else evaluates to True.

       -v value, --verbose value
           Passing value that begins with an 'f' or 'F' will evaluate to False. All else evaluates to True.

       -t value, --timing value
           Passing value that begins with an 'f' or 'F' will evaluate to False. All else evaluates to True.

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

    try:
        opts, args = getopt.getopt(argv, "hdr:i:e:v:t:", ["help", "debug", "requests=", "info=", "error=", "verbose=", "timing="])
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

        elif opt in ("-d", "--debug"):
            debug_flag = True

    beslog2json()


if __name__ == "__main__":
    main(sys.argv[1:])

