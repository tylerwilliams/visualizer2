//http://groups.google.com/group/processingjs/browse_thread/thread/9e2ed155512a82a2#

Processing.exports = {};
Processing.exports.test = test;


class Test { 
  String str;
  Test(String s) { str = s; }
  String getStr() { return str; }
  void setStr(String s) { str = s; }
  void display() { text(str, 30, 30); }
} 
