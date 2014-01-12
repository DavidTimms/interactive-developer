if require?
	coffee = require "coffee-script"
	fs = require "fs"

outputBox = $("#output")
consoleBox = $("#console")

animSpeed = 80

cmdHistory = []
cmdHistory.cursor = 0
# TODO: Use separate command history arrays for saveScript() (without errors)
#       and up/down arrows (with errors)

lang = "javascript"
compile = 
	javascript: (source) -> source

if coffee?
	compile.coffeescript = (source) -> 
		coffee.compile(source, {bare: true})
	lang = "coffeescript"

langExts = 
	js: "javascript"
	coffee: "coffeescript"

editor = ( -> 
	@setTheme("ace/theme/monokai")
	@getSession().setMode("ace/mode/coffee")
	@setBehavioursEnabled(true)
	@renderer.setShowGutter(false)
	@renderer.setPadding(15)
	@setShowPrintMargin(false)
	this
).call(ace.edit("console"))

window.pg = 
	setLang: (newLang) ->
		# TODO: change syntax highlighting when language changes
		newLang = newLang.toLowerCase()
		if newLang of compile
			lang = newLang
			"now using #{lang}"
		else
			throw new Error("#{newLang} is not a supported language")

	say: (message) -> 
		block = $("<pre class='result-block'></pre>")
			.text(message)
			.addClass("user")
		addOutputNode(block)
		return

	show: (filename) -> 
		fs.readFile filename, 'utf8', (err, content) ->
			if err then throw "Unable to read file: #{filename}"
			filetype = extension(filename)
			if filetype in ["md", "markdown", "mdown"]
				content = require("marked")(content)
				printUnescaped(content, "user")
			else if filetype in ["html", "htm"]
				printUnescaped(content, "user")
			else
				printResult(content, "user")
		return

	load: (filename) -> 
		fs.readFile filename, 'utf8', (err, content) ->
			if err then throw "Unable to read file: #{filename}"
			editor.setValue(content)
		return

	run: (filename) -> 
		fs.readFile filename, 'utf8', (err, source) ->
			try
				if err then throw "Unable to read file: #{filename}"
				filetype = extension(filename)
				filelang = langExts[filetype] || throw "Unknown file type: #{filetype}"
				compiled = compile[filelang]?(source)  || throw "Cannot compile file"
				res = eval.call(window, compiled)
				printResult "Executed successfully: #{filename}", "success"
			catch err
				printResult err, "error"
		return

	background: ->
		# TODO: List all background tasks (servers, file watchers)

	saveScript: (filename) ->
		fs.writeFile(filename, cmdHistory.join("\n\n"))
		return

	server: (port = 8080) ->
		express = require "express"
		cwd = process.cwd()
		app = express()
		app.use(express.static(cwd)).listen(port)
		"Serving #{cwd} on localhost:#{port}"

	ls: -> fs.readdirSync(".").join("\n")
	cwd: process?.cwd
	cd: (path) -> 
		process?.chdir(path)
		process?.cwd()

	exec: (command) ->
		child = require("child_process").exec(command)
		child.stdout.on "data", (output) ->
			printResult output.toString()
		child.stderr.on "data", (output) ->
			printResult output.toString(), 'error'
		return

	import: (funcName) ->
		if funcName == "all"
			window[func] = pg[func] for func of pg
		else
			if funcName not of pg
				throw "#{funcName} is not a valid playground function"
			window[funcName] = pg[funcName]
		"imported #{funcName} to global namespace"

	help: ->
		# pg.say "#{func}(): #{expl}" for func, expl of explanations
		pg.say prettify(explanations)
		return 

explanations =
	setLang: "set the language to use in the console"
	say: "print a message to the console"
	show: "display the contents of a file (renders html/markdown)"
	load: "load the contents of a file into the console"
	run: "run a JavaScript or CoffeeScript file"
	saveScript: "save the current command history to a file"
	server: "serve the current directory using a static server"
	ls: "list all files and directories in the current working directory"
	cwd: "print the current directory"
	cd: "change the current working directory"
	exec: "execute a system command"
	import: "add a playground function to the global namespace"

for exp of explanations
	do (exp) -> pg[exp]?.toString = -> explanations[exp]

extension = (filename) ->
	filename.toLowerCase().split(".").pop()

addOutputNode = (node) ->
	node.appendTo(outputBox).hide().fadeIn(animSpeed)
	(doc = $(document)).scrollTop(doc.height())

printBlock = (code) -> 
	innerBox = $("<code></code>").addClass("language-#{lang}").text(code)
	addOutputNode $("<pre class='out-block'></pre>").append(innerBox)

	Prism.highlightElement(innerBox[0])

prettifiers =
	object:
		re: "^\\[object"
		convert: (x, indent) -> 
			s = ("#{indent}#{k}: #{prettify(v, indent + '  ')}" for k, v of x)
			"\n" + s.join("\n")
	function:
		re: "^function"
		convert: (x) -> x.toString().split(")").shift() + ")"

prettify = (x, indent = "  ") ->
	pretty = x?.toString()
	for name, type of prettifiers when pretty.match(new RegExp(type.re))
		pretty = type.convert(x, indent)
	pretty


printResult = (result, msgType) -> 
	resStr = "⇒ #{prettify(result)}"
	block = $("<pre class='result-block'></pre>").text(resStr)
	if msgType then block.addClass(msgType)
	addOutputNode(block)

printUnescaped = (output, msgType) -> 
	addOutputNode $("<pre class='result-block unescaped'></pre>").html(output)

keyCodes =
	enter: 13
	up: 38
	down: 40

consoleBox.on "keydown", (e) ->
	source = editor.getValue().trim()
	if e.keyCode == keyCodes["enter"] && not e.shiftKey && source != ""
		e.preventDefault()
		editor.setValue("")
		printBlock source
		try
			compiled = compile[lang](source)
			res = eval.call(window, compiled)
			if res != undefined
				printResult res, 'success'
			cmdHistory.push(source)
			cmdHistory.cursor = cmdHistory.length
		catch err
			printResult err, "error"

consoleBox.on "keyup", (e) ->
	if e.keyCode == keyCodes["up"] && cmdHistory.cursor > 0
		cursor = cmdHistory.cursor -= 1
	else if e.keyCode == keyCodes["down"] && cmdHistory.cursor < cmdHistory.length
		cursor = cmdHistory.cursor += 1
	if cursor != undefined
		e.preventDefault()
		editor.setValue(cmdHistory[cursor])

outputBox.on "click", ".out-block", (e) ->
	editor.focus()
	editor.setValue($(this).text())

process?.on "uncaughtException", (err) ->
	printResult err, "error"