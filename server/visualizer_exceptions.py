class BaseVisualizerException(Exception):
    msg = "Unknown Error"
    def __init__(self, value=None):
        self.value = value
        super(BaseVisualizerException, self).__init__()

    def format_message(self):
        if hasattr(self, 'value') and self.value:
            return ": ".join([self.msg, str(self.value)])
        else:
            return self.msg

    def __str__(self):
        return self.format_message()

class FileNotFoundVE(BaseVisualizerException):
    msg = "Uploaded file not found"
