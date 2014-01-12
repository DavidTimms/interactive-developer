// Generated by CoffeeScript 1.6.3
(function() {
  var addOutputNode, animSpeed, cmdHistory, coffee, compile, consoleBox, editor, exp, explanations, extension, fs, keyCodes, lang, langExts, outputBox, prettifiers, prettify, printBlock, printResult, printUnescaped, _fn;

  if (typeof require !== "undefined" && require !== null) {
    coffee = require("coffee-script");
    fs = require("fs");
  }

  outputBox = $("#output");

  consoleBox = $("#console");

  animSpeed = 80;

  cmdHistory = [];

  cmdHistory.cursor = 0;

  lang = "javascript";

  compile = {
    javascript: function(source) {
      return source;
    }
  };

  if (coffee != null) {
    compile.coffeescript = function(source) {
      return coffee.compile(source, {
        bare: true
      });
    };
    lang = "coffeescript";
  }

  langExts = {
    js: "javascript",
    coffee: "coffeescript"
  };

  editor = (function() {
    this.setTheme("ace/theme/monokai");
    this.getSession().setMode("ace/mode/coffee");
    this.setBehavioursEnabled(true);
    this.renderer.setShowGutter(false);
    this.renderer.setPadding(15);
    this.setShowPrintMargin(false);
    return this;
  }).call(ace.edit("console"));

  window.pg = {
    setLang: function(newLang) {
      newLang = newLang.toLowerCase();
      if (newLang in compile) {
        lang = newLang;
        return "now using " + lang;
      } else {
        throw new Error("" + newLang + " is not a supported language");
      }
    },
    say: function(message) {
      var block;
      block = $("<pre class='result-block'></pre>").text(message).addClass("user");
      addOutputNode(block);
    },
    show: function(filename) {
      fs.readFile(filename, 'utf8', function(err, content) {
        var filetype;
        if (err) {
          throw "Unable to read file: " + filename;
        }
        filetype = extension(filename);
        if (filetype === "md" || filetype === "markdown" || filetype === "mdown") {
          content = require("marked")(content);
          return printUnescaped(content, "user");
        } else if (filetype === "html" || filetype === "htm") {
          return printUnescaped(content, "user");
        } else {
          return printResult(content, "user");
        }
      });
    },
    load: function(filename) {
      fs.readFile(filename, 'utf8', function(err, content) {
        if (err) {
          throw "Unable to read file: " + filename;
        }
        return editor.setValue(content);
      });
    },
    run: function(filename) {
      fs.readFile(filename, 'utf8', function(err, source) {
        var compiled, filelang, filetype, res;
        try {
          if (err) {
            throw "Unable to read file: " + filename;
          }
          filetype = extension(filename);
          filelang = langExts[filetype] || (function() {
            throw "Unknown file type: " + filetype;
          })();
          compiled = (typeof compile[filelang] === "function" ? compile[filelang](source) : void 0) || (function() {
            throw "Cannot compile file";
          })();
          res = eval.call(window, compiled);
          return printResult("Executed successfully: " + filename, "success");
        } catch (_error) {
          err = _error;
          return printResult(err, "error");
        }
      });
    },
    background: function() {},
    saveScript: function(filename) {
      fs.writeFile(filename, cmdHistory.join("\n\n"));
    },
    server: function(port) {
      var app, cwd, express;
      if (port == null) {
        port = 8080;
      }
      express = require("express");
      cwd = process.cwd();
      app = express();
      app.use(express["static"](cwd)).listen(port);
      return "Serving " + cwd + " on localhost:" + port;
    },
    ls: function() {
      return fs.readdirSync(".").join("\n");
    },
    cwd: typeof process !== "undefined" && process !== null ? process.cwd : void 0,
    cd: function(path) {
      if (typeof process !== "undefined" && process !== null) {
        process.chdir(path);
      }
      return typeof process !== "undefined" && process !== null ? process.cwd() : void 0;
    },
    exec: function(command) {
      var child;
      child = require("child_process").exec(command);
      child.stdout.on("data", function(output) {
        return printResult(output.toString());
      });
      child.stderr.on("data", function(output) {
        return printResult(output.toString(), 'error');
      });
    },
    "import": function(funcName) {
      var func;
      if (funcName === "all") {
        for (func in pg) {
          window[func] = pg[func];
        }
      } else {
        if (!(funcName in pg)) {
          throw "" + funcName + " is not a valid playground function";
        }
        window[funcName] = pg[funcName];
      }
      return "imported " + funcName + " to global namespace";
    },
    help: function() {
      pg.say(prettify(explanations));
    }
  };

  explanations = {
    setLang: "set the language to use in the console",
    say: "print a message to the console",
    show: "display the contents of a file (renders html/markdown)",
    load: "load the contents of a file into the console",
    run: "run a JavaScript or CoffeeScript file",
    saveScript: "save the current command history to a file",
    server: "serve the current directory using a static server",
    ls: "list all files and directories in the current working directory",
    cwd: "print the current directory",
    cd: "change the current working directory",
    exec: "execute a system command",
    "import": "add a playground function to the global namespace"
  };

  _fn = function(exp) {
    var _ref;
    return (_ref = pg[exp]) != null ? _ref.toString = function() {
      return explanations[exp];
    } : void 0;
  };
  for (exp in explanations) {
    _fn(exp);
  }

  extension = function(filename) {
    return filename.toLowerCase().split(".").pop();
  };

  addOutputNode = function(node) {
    var doc;
    node.appendTo(outputBox).hide().fadeIn(animSpeed);
    return (doc = $(document)).scrollTop(doc.height());
  };

  printBlock = function(code) {
    var innerBox;
    innerBox = $("<code></code>").addClass("language-" + lang).text(code);
    addOutputNode($("<pre class='out-block'></pre>").append(innerBox));
    return Prism.highlightElement(innerBox[0]);
  };

  prettifiers = {
    object: {
      re: "^\\[object",
      convert: function(x, indent) {
        var k, s, v;
        s = (function() {
          var _results;
          _results = [];
          for (k in x) {
            v = x[k];
            _results.push("" + indent + k + ": " + (prettify(v, indent + '  ')));
          }
          return _results;
        })();
        return "\n" + s.join("\n");
      }
    },
    "function": {
      re: "^function",
      convert: function(x) {
        return x.toString().split(")").shift() + ")";
      }
    }
  };

  prettify = function(x, indent) {
    var name, pretty, type;
    if (indent == null) {
      indent = "  ";
    }
    pretty = x != null ? x.toString() : void 0;
    for (name in prettifiers) {
      type = prettifiers[name];
      if (pretty.match(new RegExp(type.re))) {
        pretty = type.convert(x, indent);
      }
    }
    return pretty;
  };

  printResult = function(result, msgType) {
    var block, resStr;
    resStr = "⇒ " + (prettify(result));
    block = $("<pre class='result-block'></pre>").text(resStr);
    if (msgType) {
      block.addClass(msgType);
    }
    return addOutputNode(block);
  };

  printUnescaped = function(output, msgType) {
    return addOutputNode($("<pre class='result-block unescaped'></pre>").html(output));
  };

  keyCodes = {
    enter: 13,
    up: 38,
    down: 40
  };

  consoleBox.on("keydown", function(e) {
    var compiled, err, res, source;
    source = editor.getValue().trim();
    if (e.keyCode === keyCodes["enter"] && !e.shiftKey && source !== "") {
      e.preventDefault();
      editor.setValue("");
      printBlock(source);
      try {
        compiled = compile[lang](source);
        res = eval.call(window, compiled);
        if (res !== void 0) {
          printResult(res, 'success');
        }
        cmdHistory.push(source);
        return cmdHistory.cursor = cmdHistory.length;
      } catch (_error) {
        err = _error;
        return printResult(err, "error");
      }
    }
  });

  consoleBox.on("keyup", function(e) {
    var cursor;
    if (e.keyCode === keyCodes["up"] && cmdHistory.cursor > 0) {
      cursor = cmdHistory.cursor -= 1;
    } else if (e.keyCode === keyCodes["down"] && cmdHistory.cursor < cmdHistory.length) {
      cursor = cmdHistory.cursor += 1;
    }
    if (cursor !== void 0) {
      e.preventDefault();
      return editor.setValue(cmdHistory[cursor]);
    }
  });

  outputBox.on("click", ".out-block", function(e) {
    editor.focus();
    return editor.setValue($(this).text());
  });

  if (typeof process !== "undefined" && process !== null) {
    process.on("uncaughtException", function(err) {
      return printResult(err, "error");
    });
  }

}).call(this);
