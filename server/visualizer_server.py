import os
import sys
reload(sys)
sys.setdefaultencoding('utf-8')
sys.path.append( os.path.dirname(os.path.abspath( __file__ )) )
os.environ['PYTHON_EGG_CACHE'] = '/tmp'

import re
import time
import pprint
import urllib
import hashlib
import logging
import tempfile

import simplejson as json
import web
from pyechonest import config, song, track, util

import settings
import cache
import visualizer_exceptions

web.config.update({
        'debug':True,
        'server.environment': 'production',
        'staticFilter.on': True,
        'staticFilter.dir': 'static',
})

visualizer_settings = settings.get_settings() 
logger = logging.getLogger(__name__)
config.ECHO_NEST_API_KEY = visualizer_settings['echo_nest_api_key']
FILE_DIR = visualizer_settings['upload_dir']
ANALYSIS_DIR = visualizer_settings['analysis_dir']

urls = (
        '/upload',              'UploadFileHandler',
        '/analyze',             'AnalyzeHandler',
        '/files/(.*)',          'ChunkedFileDownloadHandler',
        )

class ChunkedFileDownloadHandler:
    """
        (i can't believe i had to write this web.py...)
        This is a file download handler that allows streaming files
    """
    def GET(self, name):
        if not os.path.exists(os.path.join(FILE_DIR, name)):
            raise web.notfound()
        fpath = os.path.join(FILE_DIR,name)
        total = os.stat(fpath).st_size
        f = open(fpath, 'rb')

        range = web.ctx.env.get('HTTP_RANGE')
        if range is None:
            return f.read()

        _, r = range.split("=")
        partial_start, partial_end = r.split("-")

        start = int(partial_start)

        if not partial_end:
            end = total-1
        else:
            end = int(partial_end)

        chunksize = (end-start)+1

        web.ctx.status = "206 Partial Content"
        web.header("Content-Range", "bytes %d-%d/%d" % (start, end, total))
        web.header("Accept-Ranges", "bytes")
        web.header("Content-Length", chunksize)
        f.seek(start)
        return f.read((end-start)+1)

class AnalyzeHandler:
    """
        Analyze handler

        Analyze an already uploaded file

        If the analysis already exists (verified by md5 hashs) just return it
        otherwise upload the file to The Echo Nest API then save and return the
        analysis

    """
    def POST(self, *args):
        input_params = web.input()
        file_id = input_params.get('file_id')
        file_path = get_audio_file_path_for_md5(file_id)
        if not os.path.exists(file_path):
            raise visualizer_exceptions.FileNotFoundVE(file_id)

        # ok, file exists, do we have analysis already?
        analysis_file_path = get_analysis_file_path_for_md5(file_id)
        if not os.path.exists(analysis_file_path):
            track_obj = track.track_from_filename(file_path)
            with open(analysis_file_path, 'w') as new_analysis_file:
                json.dump(track_obj.__dict__, new_analysis_file)

        with open(analysis_file_path) as analysis_file:
            analysis_dict = json.load(analysis_file)
        
        ca = clean_analysis(analysis_dict)
        return json.dumps({'analysis':ca})

class UploadFileHandler:
    """
        Upload file handler

        Upload a file (saving it to upload_dir) and return a pointer to it
        to the client.

        If the file already exists (verified by md5 hash), just return a pointer
        to the existing file.
    """
    def POST(self, *args):
        input_params = web.input()
        filetype = input_params['filetype']
        # filename = input['filename']
        filedata = input_params['file']

        temp_upload = tempfile.SpooledTemporaryFile(dir=FILE_DIR, max_size=1024*1024*10)
        upload_hash = hashlib.md5()
        temp_upload.write(filedata)
        upload_hash.update(filedata)
        upload_md5 = upload_hash.hexdigest()

        file_path = get_audio_file_path_for_md5(upload_md5)

        if not os.path.exists(file_path):
            logger.debug("writing file %s", file_path)
            temp_upload.seek(0)
            with open(file_path, 'w') as upload_file:
                upload_file.write(temp_upload.read())
        else:
            logger.info("file %s already exists!", file_path)

        return json.dumps({'file_id':upload_md5})

def check_dir(dirpath, exists=True, writable=False):
    if exists:
        if not os.path.exists(dirpath):
            raise Exception("dir %s does not exist." % dirpath)
    if writable:
        if not os.access(dirpath, os.W_OK|os.R_OK):
            raise Exception("Unable to write to %s." % dirpath)

def get_audio_file_path_for_md5(md5hash):
    filename = "audio-%s" % md5hash
    return os.path.join(FILE_DIR, filename)

def get_analysis_file_path_for_md5(md5hash):
    filename = "analysis-%s" % md5hash
    return os.path.join(ANALYSIS_DIR, filename)

def clean_analysis(analysis_dict):
    return analysis_dict

def handler_timer(handle):
    tic = time.time()
    handled = handle()
    logger.info("%s took %2.2fs", web.ctx.path+web.ctx.query, (time.time()-tic))
    return handled

class ExceptionPassingApplication(web.application):
    def handle(self):
        try:
            return web.application.handle(self)
        except (web.HTTPError, KeyboardInterrupt, SystemExit):
            raise
        except visualizer_exceptions.BaseVisualizerException, ve:
            return json.dumps({"error":ve.format_message()})            
        except Exception:
            web_input = web.input()
            fn, args = self._match(self.mapping, web.ctx.path)
            logger.exception("input = \n%s", pprint.pformat(dict(web_input)))
            new_e = visualizer_exceptions.BaseVisualizerException()
            return json.dumps({"error":new_e.format_message()}) 


def main():
    check_dir(FILE_DIR, writable=True)
    check_dir(ANALYSIS_DIR, writable=True)
    logging.basicConfig(level=logging.DEBUG, format="%(asctime)s %(message)s")
    
    app = ExceptionPassingApplication(urls, globals(), autoreload=True)
    app.add_processor(handler_timer)
    app.run()

if __name__ == "__main__":
    try:
        raise visualizer_exceptions.FileNotFoundVE("shitshitshit")
    except visualizer_exceptions.BaseVisualizerException, e:
        print "BVE:",e
    except Exception, e2:
        print "E",e2
    main()

