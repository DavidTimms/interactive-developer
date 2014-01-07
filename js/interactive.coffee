if require?
	coffee = require "coffee-script"
	_express = require "express"
	console.log "hello"
	window.express = -> 
		x = _express(arguments...)
		x.toString = ->
			"Express Server"
		x

outputBox = $("#output")
consoleBox = $("#console")

lang = "javascript"
compile = 
	coffeescript: (source) -> coffee.compile(source, {bare: true})
	javascript: (source) -> source


window.setLang = (newLang) ->
	newLang = newLang.toLowerCase()
	if newLang of compile
		lang = newLang
		"now using #{lang}"
	else
		throw new Error("#{newLang} is not a supported language")

window.say = (result, isErr) -> 
	resBox = $("<pre class='result-block'></pre>")
		.text(result)
		.css({color: 'navy'})
	outputBox.append(resBox)
	undefined

printBlock = (code) -> 
	innerBox = $("<code></code>").addClass("language-#{lang}").text(code)
	outputBox.append($("<pre class='out-block'></pre>").append(innerBox))
	Prism.highlightElement(innerBox[0])

printResult = (result, isErr) -> 
	color = if isErr then "maroon" else "darkgreen"
	resStr = result?.toString()
	if resStr.match(/\[object/)
		try 
			resStr = JSON.stringify(result)
		catch e
			resStr
	resBox = $("<pre class='result-block'></pre>")
		.text(resStr)
		.css({color: color})
	outputBox.append(resBox)

consoleBox.on "keydown", (e) ->
	source = consoleBox.val().trim()
	if e.keyCode == 13 && not e.shiftKey && source != ""
		e.preventDefault()
		consoleBox.val("")
		printBlock source
		try
			source = compile[lang](source)
			res = eval.call(window, source)
			if res != undefined
				printResult res
		catch err
			printResult err, "error"


outputBox.on "click", ".out-block", (e) ->
	consoleBox.focus().val($(this).text())

process?.on 'uncaughtException', (err) ->
	printResult err, "error"