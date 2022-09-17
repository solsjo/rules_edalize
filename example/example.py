import sys
from edalize import get_flow
import os
import re

import argparse

def setup_argparse():
    parser = argparse.ArgumentParser(description='Chart generator')
    parser.add_argument('--input', required=True, action="append")
    parser.add_argument('--output', required=True, action="append")
    return parser.parse_args()


def main():
    args = setup_argparse()

    counter_v = args.input[0]
    counter_pcf = args.input[1]
    root = args.input[2]
    Flow = get_flow("lint") # Get the class for the lint flow
    
    edam = {} #Create an initial EDAM file
    
    edam["name"] = "counter_test" # Set name of the design

    #Set all (one) files with their file type and optional attributes
    edam["files"] = [{"name" : counter_v, "file_type" : "verilogSource"}]

    #Set flow_options for the lint flow. Flow.get_flow_options() lists all options
    edam["flow_options"] = {"tool" : "verilator"}
    
    edam["toplevel"] = "counter" # Set toplevel module name
    
    #Set the design parameter width to an integer with the value 9
    edam["parameters"] = {"width": {
        "datatype": "int", "default" : 7, "paramtype" : "vlogparam"}}
    
    #Create an instance of the flow class with the EDAM and output directories as inputs
    lint = Flow(edam, '.')
    
    lint.configure() # Create the flow graph and all configuration files
    
    #Build the design. In the case of the linter flow this means compile and run linter

    curr_dir = os.path.realpath(os.getcwd())
    output_base_path = re.match("(.*/_bazel_[a-zA-Z0-9]*/[a-zA-Z0-9]*)", curr_dir).groups()[0]
    root_path = os.path.dirname(os.readlink(root))
    os.environ["EDALIZE_LAUNCHER_EXTRA_FLAGS"] = f"-v {output_base_path}:{output_base_path} -v {root_path}:{root_path}"

    try:
        lint.build()
    except RuntimeError as e:
        print(e)
        exit(1)
    
    #Let's run an FPGA flow now using the icestorm flow
    Flow2 = get_flow("icestorm")
    
    #We reuse the EDAM but change flow_options to relevant options for the icestorm flow
    edam["flow_options"] = {"nextpnr_options" : ["--up5k", "--package", "sg48"]}
    
    #We also add a pin constraint file
    edam["files"].append({"name" : counter_pcf, "file_type" : "PCF"})
    
    #And again we instantiate the flow, set up the tools and build the design
    icestorm = Flow2(edam, '.')
    icestorm.configure()
    #During the configure stage all project files and the flow graph (e.g. Makefile) is set up, but no EDA tools are run. This means we can do everything up until the build step on one machine and then export the design to another machine doing the actual build if we want. The second machine does not need to have Edalize installed
    icestorm.build()
    
    #Now we have a bitstream

if __name__ == "__main__":
    main()
