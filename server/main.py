import sys
import logging
import optparse
import visualizer_server

def main():
    logging.basicConfig(level=logging.DEBUG, format="%(asctime)s %(message)s")
    parser = optparse.OptionParser(usage="usage: %prog -c <config file>")
    
    parser.add_option("-c", "--config",
                      metavar="config_file", help="config file", default=None)
    
    (options, args) = parser.parse_args()
    sys.argv[1:] = [] # force web.py to ignore options
    visualizer_server.start_app(options.config)

if __name__ == "__main__":
    main()