import os
import sys
reload(sys)
sys.setdefaultencoding('utf-8')
sys.path.append( os.path.dirname(os.path.abspath( __file__ )) )
os.environ['PYTHON_EGG_CACHE'] = '/tmp'

import time
import copy
import pprint
import hashlib
import logging
import tempfile

import simplejson as json
import web
from pyechonest import config, track

import settings
import cache
import visualizer_exceptions

web.config.update({
        'debug':True,
        'server.environment': 'production',
})

logger = logging.getLogger(__name__)
config.ECHO_NEST_API_KEY = None
AUDIO_DIR = None
ANALYSIS_DIR = None

urls = (
        '/upload',              'UploadFileHandler',
        '/analyze',             'AnalyzeHandler',
        '/download',            'FileDownloadHandler',
        '/',                    'IndexHandler',
        )

def reload_settings(config_path=None):
    global config, AUDIO_DIR, ANALYSIS_DIR
    visualizer_settings = settings.get_settings(config_path)
    config.ECHO_NEST_API_KEY = visualizer_settings['echo_nest_api_key']
    AUDIO_DIR = visualizer_settings['upload_dir']
    ANALYSIS_DIR = visualizer_settings['analysis_dir']
    check_dir(AUDIO_DIR, writable=True)
    check_dir(ANALYSIS_DIR, writable=True)

def clean_track(track_obj):
    cleaned_track_obj = copy.copy(track_obj)
    strip_keys = ['analysis_url', 'code_version', 'cache', 'audio_md5', 
                  'analyzer_version', 'codestring', 'echoprintstring', 
                  'id', 'md5', 'sample_md5', 'synchstring', 'decoder',
                  'status']
    for strip_key in strip_keys:
        if strip_key in cleaned_track_obj:
            cleaned_track_obj.pop(strip_key)
    return cleaned_track_obj

class IndexHandler(object):
    def GET(self):
        raise web.seeother("/static/html/index.html")

class ChunkedFileDownloadHandler(object):
    """
        (i can't believe i had to write this web.py...)
        This is a file download handler that allows streaming files
    """
    def GET(self, fpath):
        if not os.path.exists(fpath):
            raise web.notfound()

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

class FileDownloadHandler(ChunkedFileDownloadHandler):
    def GET(self, *args):
        input_params = web.input()
        file_id = input_params.get('file_id')
        file_path = get_audio_file_path_for_md5(file_id)
        web.header('Content-Type', 'audio/mpeg')
        return super(FileDownloadHandler, self).GET(file_path)
    
class AnalyzeHandler(object):
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
            track_obj = clean_track(track_obj.__dict__)
            with open(analysis_file_path, 'w') as new_analysis_file:
                json.dump(track_obj, new_analysis_file)

        with open(analysis_file_path) as analysis_file:
            analysis_dict = json.load(analysis_file)

        ca = clean_analysis(analysis_dict)
        return json.dumps({'analysis':ca})

class UploadFileHandler(object):
    """
        Upload file handler

        Upload a file (saving it to upload_dir) and return a pointer to it
        to the client.

        If the file already exists (verified by md5 hash), just return a pointer
        to the existing file.
    """
    def POST(self, *args):
        input_params = web.input()
        filedata = input_params['file_data']

        temp_upload = tempfile.SpooledTemporaryFile(dir=AUDIO_DIR, max_size=1024*1024*10)
        upload_hash = hashlib.md5()
        temp_upload.write(filedata)
        upload_hash.update(filedata)
        upload_md5 = upload_hash.hexdigest()
        print "upload_md5:",upload_md5
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
    filename = "audio-%s.mp3" % md5hash
    return os.path.join(AUDIO_DIR, filename)

def get_analysis_file_path_for_md5(md5hash):
    filename = "analysis-%s.json" % md5hash
    return os.path.join(ANALYSIS_DIR, filename)

def clean_analysis(analysis_dict):
    return analysis_dict

def handler_timer(handle):
    tic = time.time()
    handled = handle()
    logger.info("%s took %2.2fs", web.ctx.path+web.ctx.query, (time.time()-tic))
    return handled

def safe_pformat(input_d):
    str_repr = pprint.pformat(dict(input_d))
    return str_repr[:1000]

class ExceptionPassingApplication(web.application):
    def handle(self):
        try:
            return web.application.handle(self)
        except (web.HTTPError, KeyboardInterrupt, SystemExit):
            raise
        except Exception, e:
            web_input = web.input()
            fn, args = self._match(self.mapping, web.ctx.path)
            web.ctx.status = "400 Bad Request"
            if isinstance(e, visualizer_exceptions.BaseVisualizerException):
                r = json.dumps({"error":e.format_message()})
            else:
                logger.exception("input = \n%s",safe_pformat(web_input))
                new_e = visualizer_exceptions.BaseVisualizerException()
                r = json.dumps({"error":new_e.format_message()})
            logger.exception("something went wrong")
            return r

def start_app(settings_path, port=8080):
    reload_settings(settings_path)
    app = ExceptionPassingApplication(urls, globals(), autoreload=True)
    # app.add_processor(handler_timer)
    # app.run()
    web.httpserver.runsimple(app.wsgifunc(), ("0.0.0.0", port))

