// Generated by CoffeeScript 1.6.3
(function() {
  var coffee, compile, consoleBox, lang, outputBox, printBlock, printResult, _express;

  if (typeof require !== "undefined" && require !== null) {
    coffee = require("coffee-script");
    _express = require("express");
    console.log("hello");
    window.express = function() {
      var x;
      x = _express.apply(null, arguments);
      x.toString = function() {
        return "Express Server";
      };
      return x;
    };
  }

  outputBox = $("#output");

  consoleBox = $("#console");

  lang = "javascript";

  compile = {
    coffeescript: function(source) {
      return coffee.compile(source, {
        bare: true
      });
    },
    javascript: function(source) {
      return source;
    }
  };

  window.setLang = function(newLang) {
    newLang = newLang.toLowerCase();
    if (newLang in compile) {
      lang = newLang;
      return "now using " + lang;
    } else {
      throw new Error("" + newLang + " is not a supported language");
    }
  };

  window.say = function(result, isErr) {
    var resBox;
    resBox = $("<pre class='result-block'></pre>").text(result).css({
      color: 'navy'
    });
    outputBox.append(resBox);
    return void 0;
  };

  printBlock = function(code) {
    var innerBox;
    innerBox = $("<code></code>").addClass("language-" + lang).text(code);
    outputBox.append($("<pre class='out-block'></pre>").append(innerBox));
    return Prism.highlightElement(innerBox[0]);
  };

  printResult = function(result, isErr) {
    var color, e, resBox, resStr;
    color = isErr ? "maroon" : "darkgreen";
    resStr = result != null ? result.toString() : void 0;
    if (resStr.match(/\[object/)) {
      try {
        resStr = JSON.stringify(result);
      } catch (_error) {
        e = _error;
        resStr;
      }
    }
    resBox = $("<pre class='result-block'></pre>").text(resStr).css({
      color: color
    });
    return outputBox.append(resBox);
  };

  consoleBox.on("keydown", function(e) {
    var err, res, source;
    source = consoleBox.val().trim();
    if (e.keyCode === 13 && !e.shiftKey && source !== "") {
      e.preventDefault();
      consoleBox.val("");
      printBlock(source);
      try {
        source = compile[lang](source);
        res = eval.call(window, source);
        if (res !== void 0) {
          return printResult(res);
        }
      } catch (_error) {
        err = _error;
        return printResult(err, "error");
      }
    }
  });

  outputBox.on("click", ".out-block", function(e) {
    return consoleBox.focus().val($(this).text());
  });

  if (typeof process !== "undefined" && process !== null) {
    process.on('uncaughtException', function(err) {
      return printResult(err, "error");
    });
  }

}).call(this);
