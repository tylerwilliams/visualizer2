function setEditorText(some_text) {
    $("#editor").text(some_text);
}

function getEditorText(some_text) {
    return $("#editor").text();
}

// $(document).ready(function()  {
//   editor = ace.edit("editor");
//   editor.setTheme("ace/theme/cobalt");
//   
//   var JavaMode = require("ace/mode/java").Mode;
//   editor.getSession().setMode(new JavaMode());
//   editor.setHighlightActiveLine(true);
//   editor.getSession().setTabSize(4);
//   editor.getSession().setUseSoftTabs(true);
//   editor.setShowPrintMargin(false);
//  
//   window.editor = editor;
// });

// $(document).ready(function()  {
//     var ide = new IDE("editor");
//     
//     window.ide = ide;
//     
//     ide.title("processing.js demo");
// 
//     //set up some default code
//     ide.code('// comments go here\n'+
// 
// 'void setup()\n'+
// '{\n'+
// '    size(200,200);\n'+
// '    background(125);\n'+
// '    fill(255);\n'+
// '    noLoop();\n'+
// '    PFont fontA = loadFont("courier");\n'+
// '    textFont(fontA, 14);\n'+
// '}\n\n'+
// 'void draw(){\n'+
// '    text("Hello Web!",20,20);\n'+
// '    println("Hello ErrorLog!");\n'+
// '}');
// 
//     //RUN BUTTON CODE
//     var p;  //processing object
//     var error;  //processing error
// 
//     // ide.button("run","/static/img/icons/run.png", function()  {
//     //  return false;
//     // });
// 
//     // ide.button("run").setAttribute("href","#canvas");
// });

// $('#container').layout();